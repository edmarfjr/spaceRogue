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
import 'package:creatures_rogue/game/components/UI/ability_button_visual.dart';
import 'package:creatures_rogue/game/components/UI/dynamic_joystick_component.dart';
import 'package:creatures_rogue/game/components/UI/hud.dart';
import 'package:creatures_rogue/game/components/UI/minimap_hud.dart';
//import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/map/dungeon_generator.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'components/player/player.dart';

class CreaturesRogueGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  // O Mundo onde o mapa, inimigos e jogador existirão
  late final World dungeonWorld;
  
  // A câmera que vai renderizar o mundo na resolução do Game Boy
  late final CameraComponent gameCamera;

  // Joystick de movimento. Não há mais joystick de mira: a mira das
  // habilidades é sempre a última direção de movimento do jogador.
  late final DynamicJoystickComponent moveJoystick;

  late Player player;
  bool _runStarted = false;
  Vector2 currentRoomIndex = Vector2.zero();

  final VoidCallback? onGameOver; 

  List<Color> colors1Level = [Palette.indigo,Palette.marromEsc];
  List<Color> colors2Level = [Palette.eggplant,Palette.chocolate];
  
  int currentLevel = 1;

  @override
  Color backgroundColor() => const Color(0xFF1E1E1E); // Cor de fundo fora do mapa

  Map loadedRooms = {};

  late Map<String, RoomData> mapData;
  late MinimapHud minimapHud;

  double freezeTmr = 0;
  double freezeTime = 0.5;

  CreaturesRogueGame({this.onGameOver});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    //debugMode = true;

    // 1. Inicializa o Mundo
    dungeonWorld = World();
    add(dungeonWorld); // Adiciona o mundo ao jogo

    _setupJoysticks();
    _setupActionButtons();

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

    final generator = DungeonGenerator(maxRooms: 12); // Gera uma dungeon com 12 salas
    mapData = generator.generate();

    // Percorre todos os dados de salas criados pelo algoritmo
    for (var roomData in mapData.values) {
      // Cria o componente visual e o adiciona ao mundo
      final room = RoomComponent(roomData, player: player);
      loadedRooms['${roomData.x},${roomData.y}'] = room;
      dungeonWorld.add(room);
    }

    currentRoomIndex = Vector2.zero();
    gameCamera.viewfinder.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);

    // Remove HUD/minimapa de uma run anterior, se houver, antes de recriar.
    gameCamera.viewport.children.whereType<Hud>().toList().forEach((h) => h.removeFromParent());
    gameCamera.viewport.children.whereType<MinimapHud>().toList().forEach((m) => m.removeFromParent());

    final hud = Hud(player: player);
    gameCamera.viewport.add(hud);

    minimapHud = MinimapHud(
      mapData: mapData,
      getCurrentLogicalRoom: () {
        return Vector2(currentRoomIndex.x + 50, currentRoomIndex.y + 50);
      },
      position: Vector2(RoomComponent.roomWidth - 15, 15),
    );
    gameCamera.viewport.add(minimapHud);

    overlays.remove('CreatureSelect');
    overlays.add('Hud');
    resumeEngine();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) { // <-- MUDOU AQUI
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

  void _setupActionButtons() {
    // Botão A: laranja. Botão B: azul. A fatia escura por cima mostra o
    // cooldown restante e some quando a habilidade fica pronta de novo.
    final cooldownColor = Colors.black.withAlpha(170);

    // Raio 30 (60dp de diâmetro) é o piso de alvo de toque do Material —
    // com 18 (36dp) o botão ficava menor que o mínimo recomendado.
    final buttonRadius = (_isDesktop ? 22.0 : 30.0);

    // Margens DERIVADAS do raio, não fixas: isso garante que os dois botões
    // nunca se sobrepõem em X, não importa o valor de buttonRadius. B fica
    // "gap" de distância à esquerda de A, sempre — ajustar só o raio nunca
    // quebra esse espaçamento.
    const double edgeMargin = 20;
    const double gap = 10;
    final double marginRightA = edgeMargin;
    final double marginRightB = edgeMargin + buttonRadius * 2 + gap;

    final abilityButton1 = HudButtonComponent(
      button: AbilityButtonVisual(
        radius: buttonRadius,
        text:'A',
        baseColor: Palette.laranja.withAlpha(220),
        cooldownColor: cooldownColor,
        cooldownFraction: () => _runStarted ? player.ability1CooldownFraction : 0.0,
      ),
      buttonDown: AbilityButtonVisual(
        radius: buttonRadius,
        text:'A',
        baseColor: Palette.laranja.withAlpha(140),
        cooldownColor: cooldownColor,
        cooldownFraction: () => _runStarted ? player.ability1CooldownFraction : 0.0,
      ),
      margin: EdgeInsets.only(right: marginRightA, bottom: 80),
      // Segurar mantém disparando: o botão só marca "está sendo pressionado",
      // quem decide a hora certa de atirar é o cooldown lá no Player.update().
      onPressed: () {
        if (_runStarted) player.touchHoldAbility1 = true;
      },
      onReleased: () {
        if (_runStarted) player.touchHoldAbility1 = false;
      },
      onCancelled: () {
        if (_runStarted) player.touchHoldAbility1 = false;
      },
    );

    final abilityButton2 = HudButtonComponent(
      button: AbilityButtonVisual(
        radius: buttonRadius,
        text:'B',
        baseColor: Palette.azul.withAlpha(220),
        cooldownColor: cooldownColor,
        cooldownFraction: () => _runStarted ? player.ability2CooldownFraction : 0.0,
      ),
      buttonDown: AbilityButtonVisual(
        radius: buttonRadius,
        text:'B',
        baseColor: Palette.azul.withAlpha(140),
        cooldownColor: cooldownColor,
        cooldownFraction: () => _runStarted ? player.ability2CooldownFraction : 0.0,
      ),
      margin: EdgeInsets.only(right: marginRightB, bottom: 35),
      onPressed: () {
        if (_runStarted) player.touchHoldAbility2 = true;
      },
      onReleased: () {
        if (_runStarted) player.touchHoldAbility2 = false;
      },
      onCancelled: () {
        if (_runStarted) player.touchHoldAbility2 = false;
      },
    );

    add(abilityButton1);
    add(abilityButton2);
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

    // 2. GERAÇÃO DE NOVO MAPA
    // Você pode até aumentar o maxRooms a cada nível se quiser um desafio maior!
    final generator = DungeonGenerator(maxRooms: 12);
    mapData = generator.generate();

    for (var roomData in mapData.values) {
      final room = RoomComponent(roomData, player: player);
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