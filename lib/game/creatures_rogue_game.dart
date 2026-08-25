import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
//import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
//import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyDownEvent;
import 'package:flame/input.dart';
import 'package:creatures_rogue/game/components/UI/ability_button.dart';
import 'package:creatures_rogue/game/components/UI/ability_icons.dart';
import 'package:creatures_rogue/game/components/UI/consumable_slot_button.dart';
import 'package:creatures_rogue/game/components/UI/gesture_action_area.dart';
import 'package:creatures_rogue/game/components/UI/pointer_tracker.dart';
import 'package:creatures_rogue/game/components/UI/blind_overlay.dart';
import 'package:creatures_rogue/game/components/UI/boss_health_bar.dart';
import 'package:creatures_rogue/game/components/UI/dynamic_joystick_component.dart';
import 'package:creatures_rogue/game/components/UI/hud.dart';
import 'package:creatures_rogue/game/components/enemies/boss_registry.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/UI/minimap_hud.dart';
//import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/map/dungeon_generator.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'components/player/player.dart';

/// Como o jogador aciona as duas habilidades. Os dois caminhos convivem no
/// código; quem escolhe é `CreaturesRogueGame.controlScheme`, ajustado pelo
/// seletor da tela de configurações e persistido por `GameSettings`.
enum ControlScheme {
  /// Dois botões A/B no canto inferior direito. Ver [AbilityButton].
  botoes,

  /// Metade direita da tela vira área de gesto: toque parado = habilidade 1,
  /// arrastar o dedo = habilidade 2. Ver [GestureActionArea].
  gestos;

  /// Nome curto pro seletor.
  String get rotulo => switch (this) {
    ControlScheme.botoes => 'BOTÕES',
    ControlScheme.gestos => 'GESTOS',
  };

  /// Uma linha explicando o esquema, porque nenhum dos dois é óbvio de
  /// adivinhar só pelo nome.
  String get descricao => switch (this) {
    ControlScheme.botoes =>
      'Botões A e B no canto direito. Segurar mantém disparando.',
    ControlScheme.gestos =>
      'Metade direita da tela: toque parado = A, arrastar o dedo = B.',
  };
}

class CreaturesRogueGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  // O Mundo onde o mapa, inimigos e jogador existirão
  late final World dungeonWorld;
  
  // A câmera que vai renderizar o mundo na resolução do Game Boy
  late final CameraComponent gameCamera;

  // Joystick de movimento. Não há mais joystick de mira: a mira das
  // habilidades é sempre a última direção de movimento do jogador.
  late final DynamicJoystickComponent moveJoystick;

  /// Posição de todos os dedos na tela. Os botões de habilidade consultam isso
  /// pra se ativarem quando um dedo desliza para dentro deles, e não só quando
  /// um toque nasce ali (ver AbilityButton).
  late final PointerTracker pointerTracker;

  late Player player;
  bool _runStarted = false;
  Vector2 currentRoomIndex = Vector2.zero();

  final VoidCallback? onGameOver;

  ControlScheme _controlScheme;

  /// Esquema de controle montado agora. Atribuir troca os componentes de
  /// controle na hora — dá pra alternar nas configurações e ver o efeito na
  /// run seguinte sem reiniciar o app. Gravar em disco é papel de
  /// `GameSettings`, não deste setter (que é síncrono).
  ControlScheme get controlScheme => _controlScheme;

  set controlScheme(ControlScheme scheme) {
    if (scheme == _controlScheme) return;
    _controlScheme = scheme;
    // Antes do onLoad não há o que remontar: o próprio onLoad monta.
    if (isLoaded) _setupAbilityControls();
  }

  int currentLevel = 1;
  int numFloors = 5;
  int currentFloor = 1;

  /// De quantos em quantos andares aparece um boss. 5 combina com os 5 temas
  /// de `DungeonTheme.levelThemes` (um por andar do ciclo). **Baixe pra 2
  /// enquanto estiver ajustando um boss** — senão cada teste custa uma run
  /// inteira.
  static const int andaresPorBoss = 5;

  /// Boss sorteado no começo da run e mantido até ela acabar, pra dar tempo de
  /// revelar ao jogador o que espera no andar final. Null = nada pendente pra
  /// desbloquear, e o andar de boss vira andar comum.
  BossOption? runBoss;

  final Random _bossRandom = Random();

  bool get isBossFloor => currentFloor % andaresPorBoss == 0;

  @override
  Color backgroundColor() => const Color(0xFF1E1E1E); // Cor de fundo fora do mapa

  Map loadedRooms = {};

  late Map<String, RoomData> mapData;
  late MinimapHud minimapHud;

  double freezeTmr = 0;
  double freezeTime = 0.5;

  CreaturesRogueGame({
    this.onGameOver,
    ControlScheme controlScheme = ControlScheme.botoes,
  }) : _controlScheme = controlScheme;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    //debugMode = true;

    // 1. Inicializa o Mundo
    dungeonWorld = World();
    add(dungeonWorld); // Adiciona o mundo ao jogo

    pointerTracker = PointerTracker();
    add(pointerTracker);

    // Os três ícones de habilidade ficam em memória antes dos controles: os
    // botões nascem aqui, sem jogador ainda, e escolhem o ícone na hora de
    // desenhar conforme a criatura da run.
    await AbilityIcons.carregar();

    _setupJoysticks();
    _setupAbilityControls();
    _setupInventorySlots();

    // Pré-processa a paleta dos sprites que aparecem em pleno combate.
    // Sem isso, o PRIMEIRO tiro / explosão / morte de inimigo gerava uma
    // textura nova em tempo de execução (travadinha na hora do disparo).
    await _preloadCombatSprites();

    // 2. Configura a Câmera (Resolução Fixa: 160 x 144). Não depende do
    // jogador, então já pode ser montada aqui — a run em si só começa
    // quando o jogador escolhe uma criatura no CreatureSelectOverlay.
    gameCamera = CameraComponent.withFixedResolution(
      width: RoomComponent.roomWidth,
      height: RoomComponent.roomHeight,
      world: dungeonWorld,
    );
    gameCamera.viewfinder.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);
    add(gameCamera);

    pauseEngine();
  }

  /// Começa uma run nova com a criatura escolhida no seletor. Pode ser
  /// chamado mais de uma vez: voltar ao menu e escolher outra criatura
  /// derruba a run anterior (jogador e dungeon) e monta tudo de novo.
  void startRun(CreatureData creature) {
    for (final child in dungeonWorld.children.toList()) {
      child.removeFromParent();
    }
    loadedRooms.clear();

    player = Player(moveJoystick: moveJoystick, creatureData: creature);
    _runStarted = true;
    player.onDeath = _handleGameOver;
    player.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);
    dungeonWorld.add(player);

    // Run nova: volta pro primeiro andar e sorteia o boss que espera no
    // andar final desta run.
    currentLevel = 1;
    currentFloor = 1;
    runBoss = BossRegistry.sortearPendente(_bossRandom);

    final generator = DungeonGenerator(maxRooms: 12); // Gera uma dungeon com 12 salas
    mapData = generator.generate();

    // Percorre todos os dados de salas criados pelo algoritmo
    for (var roomData in mapData.values) {
      // Cria o componente visual e o adiciona ao mundo
      final room = RoomComponent(
        roomData,
        player: player,
        currentLevel: currentLevel,
        currentFloor: currentFloor,
        bossBuilder: isBossFloor ? _buildRunBoss : null,
      );
      loadedRooms['${roomData.x},${roomData.y}'] = room;
      dungeonWorld.add(room);
    }

    currentRoomIndex = Vector2.zero();
    gameCamera.viewfinder.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);

    // Remove HUD/minimapa de uma run anterior, se houver, antes de recriar.
    gameCamera.viewport.children.whereType<Hud>().toList().forEach((h) => h.removeFromParent());
    gameCamera.viewport.children.whereType<MinimapHud>().toList().forEach((m) => m.removeFromParent());
    // Barra de boss de uma run anterior: o boss dela já foi removido junto com
    // o mundo, mas a barra vive na viewport e sobraria órfã.
    gameCamera.viewport.children.whereType<BossHealthBar>().toList().forEach((b) => b.removeFromParent());
    gameCamera.viewport.children.whereType<BlindOverlay>().toList().forEach((c) => c.removeFromParent());

    final hud = Hud(player: player);
    gameCamera.viewport.add(hud);

    gameCamera.viewport.add(BlindOverlay(player: player, camera: gameCamera));

    minimapHud = MinimapHud(
      mapData: mapData,
      getCurrentLogicalRoom: () {
        return Vector2(currentRoomIndex.x + 50, currentRoomIndex.y + 50);
      },
      position: Vector2(RoomComponent.roomWidth - 5, 5),
    );
    gameCamera.viewport.add(minimapHud);

    overlays.remove('CreatureSelect');

    // Boss pendente nesta run: mostra quem espera no andar final antes de
    // liberar o jogo. Motor continua pausado até `dismissBossReveal`.
    if (runBoss != null) {
      overlays.add('BossReveal');
    } else {
      overlays.add('Hud');
      resumeEngine();
    }
  }

  /// Chamado pelo botão "ENTRAR" do `BossRevealOverlay`.
  void dismissBossReveal() {
    overlays.remove('BossReveal');
    overlays.add('Hud');
    resumeEngine();
  }

  /// Constrói o boss da run e pendura a barra de vida na viewport. Passado
  /// como `bossBuilder` pra sala de boss, que decide QUANDO chamar (quando o
  /// jogador entra). Null quando não há boss pendente — a sala então spawna
  /// inimigos comuns.
  Enemy? _buildRunBoss(Vector2 position) {
    final option = runBoss;
    if (option == null) return null;

    final boss = option.builder(position, player);
    // A barra se auto-remove quando o boss sai do mundo, então é só somar.
    gameCamera.viewport.add(BossHealthBar(boss: boss, nome: option.nome));
    return boss;
  }

  /// ATALHO DE TESTE (F1): joga um boss na frente do jogador sem precisar
  /// chegar no andar final. Sempre o primeiro do registry, pra ser
  /// determinístico durante o ajuste de números.
  void _spawnTestBoss() {
    if (!_runStarted) return;

    final option = BossRegistry.all.first;
    final boss = option.builder(player.position + Vector2(0, -40), player);
    dungeonWorld.add(boss);
    gameCamera.viewport.add(BossHealthBar(boss: boss, nome: option.nome));
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) { // <-- MUDOU AQUI
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f1) {
      _spawnTestBoss();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (!overlays.isActive('MainMenu')) { 
        if (overlays.isActive('PauseMenu')) {
          overlays.remove('PauseMenu');
          resumeEngine();
        } else {
          pauseEngine();
          overlays.add('PauseMenu');
        }
      }
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    // Garante que o minimapa e o joystick fiquem nos lugares certos se a tela girar ou mudar
    // Você pode acessar os filhos do jogo filtrando pelo tipo deles:
   // children.whereType<MinimapHud>().forEach((minimap) {
   //   minimap.position = Vector2(canvasSize.x - 40, 40);
   // });
    
    // Exemplo para o joystick caso ele esteja se perdendo:
    // moveJoystick.position = Vector2(80, canvasSize.y - 80);
  }

  Future<void> _preloadCombatSprites() async {
    await PaletteSwapper.warmUp([
      // Tiro do player (Projectile padrão)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/tiro.png',
        lightGrayReplacement: Palette.azul,
        darkGrayReplacement: Palette.verdeEsc,
      ),
      // Tiro dos inimigos (Enemy.bltImg padrão)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/tiro2.png',
        lightGrayReplacement: Palette.vermelho,
        darkGrayReplacement: Palette.laranja,
      ),
      // Bomba
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/bomb.png',
        lightGrayReplacement: Palette.indigo,
        darkGrayReplacement: Palette.azulEsc,
      ),
      // Efeito de morte de inimigo
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/enemy_death.png',
        lightGrayReplacement: Palette.indigo,
        darkGrayReplacement: Palette.cinzaEsc,
        whiteReplacement: Palette.branco,
      ),
      // Drops de vida
      PaletteSwapper.createSwappedImage(
        imagePath: 'items/heartHalf.png',
        lightGrayReplacement: Palette.vermelho,
        darkGrayReplacement: Palette.roxoEsc,
      ),
      // Drop de bomba
      PaletteSwapper.createSwappedImage(
        imagePath: 'items/bomb.png',
        lightGrayReplacement: Palette.indigo,
        darkGrayReplacement: Palette.azulEsc,
      ),
      // Bolha das habilidades defensivas (Bolha Protetora, Casco Fechado)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/bolha.png',
        lightGrayReplacement: Palette.azul,
        darkGrayReplacement: Palette.azulEsc,
        whiteReplacement: Palette.branco,
      ),
    ]);
  }

  /// Desktop usa mouse, não polegar: não precisa do piso de 48dp do Material.
  /// Os controles ficam menores lá pra não dominar uma janela pequena.
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  void _setupJoysticks() {
    // Estilo do joystick
    final knobPaint = BasicPalette.lightGray.withAlpha(200).paint();
    final bgPaint = BasicPalette.black.withAlpha(100).paint();

    final scale = _isDesktop ? 0.75 : 1.0;

    // Joystick Esquerdo (Movimento). A mira sumiu: a mira das habilidades
    // agora é sempre a última direção de movimento (ver Player.lockedFireDirection).
    //
    // Flutuante: não fica fixo num canto — nasce onde o dedo toca, dentro da
    // metade esquerda da tela (spawnAreaSize cobre só essa metade), e some
    // ao soltar. Ver DynamicJoystickComponent pro porquê de não reaproveitar
    // o JoystickComponent fixo do Flame aqui.
    moveJoystick = DynamicJoystickComponent(
      knob: CircleComponent(radius: 26 * scale, paint: knobPaint),
      background: CircleComponent(radius: 60 * scale, paint: bgPaint),
      spawnAreaSize: Vector2(size.x / 2, size.y),
    );

    // Adicionamos o joystick DIRETAMENTE ao jogo, e não ao World.
    // Isso garante que ele seja tratado como HUD (Interface) e
    // não sofra o zoom/escala da resolução de 160x144.
    add(moveJoystick);
  }

  /// Componentes de controle montados pelo esquema atual, guardados pra poder
  /// desmontar na troca. Uma lista própria, e não uma varredura por tipo em
  /// `children`, porque `add` do Flame é diferido: um componente adicionado e
  /// trocado no mesmo frame ainda não apareceria em `children`.
  final List<Component> _abilityControls = [];

  /// (Re)monta o esquema de controle escolhido. Idempotente: derruba o que o
  /// esquema anterior tinha posto antes de montar o novo, então serve tanto pro
  /// onLoad quanto pra troca em runtime.
  void _setupAbilityControls() {
    for (final control in _abilityControls) {
      control.removeFromParent();
    }
    _abilityControls.clear();

    // Se a troca aconteceu com o dedo na tela, o componente removido nunca vai
    // mandar o "soltou" — sem isso o jogador ficaria disparando pra sempre.
    if (_runStarted) {
      player.touchHoldAbility1 = false;
      player.touchHoldAbility2 = false;
    }

    switch (_controlScheme) {
      case ControlScheme.botoes:
        _setupActionButtons();
      case ControlScheme.gestos:
        _setupGestureControls();
    }

    addAll(_abilityControls);
  }

  /// Metade direita da tela como área de gesto, sem botão desenhado. Note que
  /// nesse esquema não há mais o indicador visual de cooldown que o botão
  /// desenhava.
  void _setupGestureControls() {
    _abilityControls.add(
      GestureActionArea(
        // Toque parado = habilidade 1 (o antigo botão A). Manter o dedo mantém
        // disparando, igual ao botão: quem decide a hora certa de atirar é o
        // cooldown lá no Player.update().
        onTapHoldChanged: (active) {
          if (_runStarted) player.touchHoldAbility1 = active;
        },
        // Arrastar = habilidade 2 (o antigo botão B).
        onDragHoldChanged: (active) {
          if (_runStarted) player.touchHoldAbility2 = active;
        },
      ),
    );
  }

  /// Os dois slots de item de uso único. Montados uma única vez, fora de
  /// [_abilityControls]: eles não dependem do esquema de controle e não podem
  /// ser derrubados quando o jogador troca de esquema nas configurações.
  ///
  /// Ficam na faixa reservada do topo (ver `ConsumableSlotButton.alturaFaixa`),
  /// que o joystick e a área de gestos descontam da própria altura.
  void _setupInventorySlots() {
    final raio = _isDesktop ? 16.0 : 26.0;
    const double margemEsquerda = 16.0;
    const double gap = 10.0;

    for (int i = 0; i < 2; i++) {
      add(ConsumableSlotButton(
        radius: raio,
        // Índice capturado por valor no loop: cada slot lê o seu.
        conteudo: () => _runStarted ? player.slots[i] : null,
        onUsar: () {
          if (_runStarted) player.useSlot(i);
        },
        margin: EdgeInsets.only(
          top: 10,
          left: margemEsquerda + i * (raio * 2 + gap),
        ),
      ));
    }
  }

  void _setupActionButtons() {
    // Botão A e B: cinza, mais transparente enquanto pressionado. O cooldown
    // não aparece mais aqui — está nos indicadores da Hud, que servem aos dois
    // esquemas de controle.
    // Raio 30 (60dp de diâmetro) é o piso de alvo de toque do Material —
    // com 18 (36dp) o botão ficava menor que o mínimo recomendado.
    final buttonRadius = (_isDesktop ? 22.0 : 50.0);

    // Margens DERIVADAS do raio, não fixas: isso garante que os dois botões
    // nunca se sobrepõem em X, não importa o valor de buttonRadius. B fica
    // "gap" de distância à esquerda de A, sempre — ajustar só o raio nunca
    // quebra esse espaçamento.
    const double edgeMargin = 20;
    const double gap = 10;
    final double marginRightA = edgeMargin;
    final double marginRightB = edgeMargin + buttonRadius * 2 + gap;

    _abilityControls.add(
      AbilityButton(
        radius: buttonRadius,
        tipo: () => _runStarted ? player.creatureData.ability1.tipo : AbilityTipo.ataque,
        baseColor: Palette.burgundy.withAlpha(255),
        pressedColor: Palette.burgundy.withAlpha(140),
        pointerTracker: pointerTracker,
        margin: EdgeInsets.only(right: marginRightA, bottom: 80),
        // Manter pressionado mantém disparando: o botão só reporta "está sendo
        // pressionado", quem decide a hora certa de atirar é o cooldown lá no
        // Player.update().
        onPressedChanged: (pressed) {
          if (_runStarted) player.touchHoldAbility1 = pressed;
        },
      ),
    );

    _abilityControls.add(
      AbilityButton(
        radius: buttonRadius,
        tipo: () => _runStarted ? player.creatureData.ability2.tipo : AbilityTipo.defesa,
        baseColor: Palette.burgundy.withAlpha(255),
        pressedColor: Palette.burgundy.withAlpha(140),
        pointerTracker: pointerTracker,
        margin: EdgeInsets.only(right: marginRightB, bottom: 35),
        onPressedChanged: (pressed) {
          if (_runStarted) player.touchHoldAbility2 = pressed;
        },
      ),
    );
  }

  @override
  void update(double dt) {
    if (freezeTmr > 0) {
      freezeTmr -= dt;
      return;
    }
    super.update(dt);
    _checkCameraTransition();
  }
// NOVO MÉTODO: Limpa e recria a fase!
  void nextLevel() {
    // 1. LIMPEZA TOTAL (O "faxineiro")
    // Remove salas velhas, tiros perdidos, itens no chão... tudo, MENOS o jogador!
    for (var child in dungeonWorld.children) {
      if (child != player) {
        child.removeFromParent();
      }
    }
    loadedRooms.clear();

    // 2. AVANÇA O ANDAR
    // Sem isso o contador ficava travado em 1 pra sempre — e como o tema da
    // sala vem de `getThemeForLevel`, os outros 4 temas nunca apareciam.
    
    currentFloor++;

    if(currentFloor > numFloors){
      currentLevel++;
      currentFloor=1;
    }

    // 3. GERAÇÃO DE NOVO MAPA
    // Você pode até aumentar o maxRooms a cada nível se quiser um desafio maior!
    final generator = DungeonGenerator(maxRooms: 12);
    mapData = generator.generate();

    for (var roomData in mapData.values) {
      final room = RoomComponent(
        roomData,
        player: player,
        currentLevel: currentLevel,
        currentFloor:currentFloor,
        bossBuilder: isBossFloor ? _buildRunBoss : null,
      );
      loadedRooms['${roomData.x},${roomData.y}'] = room;
      dungeonWorld.add(room);
    }

    // 3. REPOSICIONAMENTO DO JOGADOR E CÂMERA
    // Volta o jogador para o centro lógico da fase (Sala Inicial)
    player.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);
    currentRoomIndex = Vector2.zero();
    
    // Dá um "corte seco" na câmera de volta para o início
    gameCamera.viewfinder.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);

    // 4. ATUALIZA O MINIMAPA
    // Entrega o novo mapa para a HUD e limpa o contorno antigo
    minimapHud.mapData = mapData;
  }

  /// Chamado pelo `Player.onDeath` quando a vida chega a zero. Congela o jogo
  /// e troca a Hud pela tela de Game Over — as ações de RESTART/MENU dela já
  /// esperam o motor pausado (ver comentário em game_over_overlay.dart).
  void _handleGameOver() {
    overlays.remove('Hud');
    overlays.add('GameOver');
    pauseEngine();
    onGameOver?.call();
  }

  /// Reseta a run inteira, não só o jogador: `startRun` já limpa todo mundo
  /// (inimigos incluídos) e gera uma dungeon nova do zero, então reaproveita
  /// ele em vez de tentar remendar o estado da run anterior.
  void resetGame() {
    freezeTmr = 0;
    startRun(player.creatureData);
  }

  void _checkCameraTransition() {
    final double roomWidth = RoomComponent.roomWidth;
    final double roomHeight = RoomComponent.roomHeight;
    final double threshold = 8.0; 

    double roomLeft = currentRoomIndex.x * roomWidth;
    double roomRight = roomLeft + roomWidth;
    double roomTop = currentRoomIndex.y * roomHeight;
    double roomBottom = roomTop + roomHeight;

    int newRoomX = currentRoomIndex.x.toInt();
    int newRoomY = currentRoomIndex.y.toInt();
    bool transitioned = false;

    if (player.position.x > roomRight - threshold) {
      newRoomX++;
      transitioned = true;
    } else if (player.position.x < roomLeft + threshold) {
      newRoomX--;
      transitioned = true;
    } else if (player.position.y > roomBottom - threshold) {
      newRoomY++;
      transitioned = true;
    } else if (player.position.y < roomTop + threshold) {
      newRoomY--;
      transitioned = true;
    }

    if (transitioned) {
      player.naoMove = true;
      
      double pushDistance = 40.0; 

      if (newRoomX > currentRoomIndex.x) {
        player.position.x += pushDistance;
      } else if (newRoomX < currentRoomIndex.x) {
        player.position.x -= pushDistance;
      } else if (newRoomY > currentRoomIndex.y) {
        player.position.y += pushDistance;
      } else if (newRoomY < currentRoomIndex.y) {
        player.position.y -= pushDistance;
      }

      currentRoomIndex = Vector2(newRoomX.toDouble(), newRoomY.toDouble());

      int logicalX = newRoomX + 50;
      int logicalY = newRoomY + 50;
      loadedRooms['$logicalX,$logicalY']?.onPlayerEnter();

      Vector2 newCameraPosition = Vector2(
        (newRoomX * roomWidth) + (roomWidth / 2),
        (newRoomY * roomHeight) + (roomHeight / 2),
      );

      gameCamera.viewfinder.add(
        MoveToEffect(
          newCameraPosition,
          EffectController(duration: 0.4, curve: Curves.easeInOut),
          onComplete: () {
            player.naoMove = false;
            freezeTmr = freezeTime;
          }
        ),
      );
    }
  }
}