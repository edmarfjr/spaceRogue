import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
//import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
//import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyDownEvent;
import 'package:flame/input.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/components/UI/gameboy_bezel.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/UI/ability_button.dart';
import 'package:creatures_rogue/game/components/UI/ability_icons.dart';
import 'package:creatures_rogue/game/components/effects/companion_recall_effect.dart';
import 'package:creatures_rogue/game/components/effects/companion_revive_effect.dart';
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
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/wild_creature_npc.dart';
import 'package:creatures_rogue/game/components/map/dungeon_generator.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
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
  String rotulo(BuildContext context) => switch (this) {
    ControlScheme.botoes => context.l10n.settings_controleBotoes,
    ControlScheme.gestos => context.l10n.settings_controleGestos,
  };

  /// Uma linha explicando o esquema, porque nenhum dos dois é óbvio de
  /// adivinhar só pelo nome.
  String descricao(BuildContext context) => switch (this) {
    ControlScheme.botoes => context.l10n.settings_controleBotoesDesc,
    ControlScheme.gestos => context.l10n.settings_controleGestosDesc,
  };
}

class CreaturesRogueGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
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

  /// Grupo de até três criaturas — a ativa (quem o `Player` está sendo agora)
  /// mais o banco (ver PIVOT_CONTROLE_DIRETO.md §2.3). Slot 0 é sempre a
  /// criatura escolhida na seleção; 1 e 2 ficam vazios (`null`) até a
  /// criatura selvagem da sala da escada preencher (ver [_buildWildCreature]).
  static const int maxCompanions = 3;

  /// Qual slot é a criatura que o `Player` está sendo agora. Os outros dois
  /// estão sempre no banco (`companionPocketed[i] == true`), vazios, ou
  /// curando ainda abaixo do piso de disponibilidade.
  int companionAtivoIndex = 0;

  /// A criatura de cada slot — sobrevive à troca (o `Player` muta pra virar
  /// outra, não recria componente nenhum). É o que a Hud usa pra desenhar o
  /// retrato de cada slot, e o que [_trocarParaSlot]/[pocketarSlotAtivo] usam
  /// pra saber quem está esperando no banco.
  final List<CreatureData?> companionCreatures = List<CreatureData?>.filled(
    maxCompanions,
    null,
  );

  /// `true` pra todo slot que não é a ativa agora — banco, na prática só o
  /// slot ativo (`companionAtivoIndex`) fica com `false`. Nome mantido do
  /// sistema de bolso original: um slot fica no banco por dois motivos, o
  /// jogador trocou de ativa (ver [_trocarParaSlot]) ou a ativa bateu 0 de
  /// vida em combate (ver [pocketarSlotAtivo]) — os dois usam o mesmo estado
  /// e a mesma cura passiva, só a origem é diferente.
  final List<bool> companionPocketed = List<bool>.filled(maxCompanions, false);

  /// Vida salva de cada slot do banco — o `Player` só existe como UMA
  /// criatura por vez, então a vida de quem está no banco não vive em
  /// componente nenhum, só aqui. Restaurada (via `trocarCriatura`) quando o
  /// slot volta a ficar ativo.
  final List<double> companionSavedHealth = List<double>.filled(
    maxCompanions,
    0.0,
  );

  /// XP e evolução de cada slot (ver PIVOT_EVOLUCAO) — mesmo padrão de
  /// `companionSavedHealth`: o `Player` só existe como UMA criatura por vez,
  /// então o progresso de quem está no banco só vive aqui, restaurado (via
  /// `trocarCriatura`) quando o slot volta a ficar ativo.
  final List<double> companionXp = List<double>.filled(maxCompanions, 0.0);
  final List<bool> companionEvoluida = List<bool>.filled(maxCompanions, false);

  /// Sem cura passiva no banco (pedido do usuário) — a vida de um slot só
  /// muda quando ele está ativo levando dano, ou quando `trocarCriatura`
  /// restaura a vida salva ao entrar em campo. Um slot no banco fica
  /// congelado na vida com que saiu até o jogador trocar pra ele de novo.
  final Random _wildRandom = Random();

  /// Disponível = tem dono e ainda tem vida — sem cura passiva, "abaixo de um
  /// piso" não existe mais: ou a criatura está viva (qualquer vida > 0) e
  /// pode entrar, ou já bateu 0 e só volta se algo restaurar a vida dela
  /// (nada faz isso hoje).
  bool slotDisponivel(int slot) {
    final creature = companionCreatures[slot];
    if (creature == null || !companionPocketed[slot]) return false;
    return companionSavedHealth[slot] > 0;
  }

  /// Próximo slot vivo da lista, na ordem 0/1/2 (pulando a ativa) — troca
  /// automática ao desmaiar (ver [pocketarSlotAtivo]) usa o primeiro que
  /// achar, não o "mais saudável" ou qualquer outro critério.
  int? _primeiroSlotDisponivel() {
    for (int i = 0; i < maxCompanions; i++) {
      if (i != companionAtivoIndex && slotDisponivel(i)) return i;
    }
    return null;
  }

  /// Toque num retrato do banco (ver [onTapCompanionSlot]): a ativa atual
  /// entra no banco com a vida que tinha NA HORA, e [slot] assume — sem
  /// recriar componente nenhum, `Player.trocarCriatura` muta a instância que
  /// já existe.
  void _trocarParaSlot(int slot) {
    final creature = companionCreatures[slot];
    if (creature == null) return;

    final slotAntigo = companionAtivoIndex;
    companionCreatures[slotAntigo] = player.creatureData;
    companionSavedHealth[slotAntigo] = player.currentHealth;
    companionPocketed[slotAntigo] = true;
    companionXp[slotAntigo] = player.xp;
    companionEvoluida[slotAntigo] = player.evoluida;

    final vidaSalva = companionSavedHealth[slot];
    companionPocketed[slot] = false;
    companionAtivoIndex = slot;

    GameAudio.instance.play(Sfx.liberar);
    player.trocarCriatura(
      creature,
      vidaSalva: vidaSalva,
      xpSalvo: companionXp[slot],
      evoluidaSalva: companionEvoluida[slot],
    );
    dungeonWorld.add(CompanionReviveEffect(position: player.position.clone()));
  }

  /// Toque em qualquer retrato do grupo — ver `Hud`/`CompanionPortraitIndicator`.
  /// Tocar o retrato já ativo não faz nada (sem postura pra ciclar). Tocar um
  /// slot vazio, ou uma criatura já derrotada (vida 0, sem cura passiva pra
  /// trazer de volta), também não.
  void onTapCompanionSlot(int slot) {
    if (slot == companionAtivoIndex) return;
    if (slotDisponivel(slot)) _trocarParaSlot(slot);
  }

  /// A ativa bateu 0 de vida em combate (chamado por `Player.takeDamage`):
  /// vai pro banco com vida 0 e o jogo troca sozinho pro primeiro slot
  /// disponível. Sem ninguém disponível, é Game Over — mesmo grupo esgotado
  /// que o modelo antigo tratava como "a criatura morreu".
  void pocketarSlotAtivo() {
    final slotAtual = companionAtivoIndex;
    companionCreatures[slotAtual] = player.creatureData;
    companionSavedHealth[slotAtual] = 0.0;
    companionPocketed[slotAtual] = true;
    companionXp[slotAtual] = player.xp;
    companionEvoluida[slotAtual] = player.evoluida;
    GameAudio.instance.play(Sfx.retorno);
    dungeonWorld.add(
      CompanionRecallEffect(
        position: player.position.clone(),
        trainerPosition: () => player.position,
      ),
    );

    final proximo = _primeiroSlotDisponivel();
    if (proximo == null) {
      _handleGameOver();
      return;
    }

    final creature = companionCreatures[proximo]!;
    final vidaSalva = companionSavedHealth[proximo];
    companionPocketed[proximo] = false;
    companionAtivoIndex = proximo;
    player.trocarCriatura(
      creature,
      vidaSalva: vidaSalva,
      xpSalvo: companionXp[proximo],
      evoluidaSalva: companionEvoluida[proximo],
    );
    dungeonWorld.add(CompanionReviveEffect(position: player.position.clone()));
  }

  /// Criatura selvagem da sala da escada do quarto andar (ver
  /// PIVOT_CONTROLE_DIRETO.md §5) — passado como `wildCreatureBuilder` pra
  /// `RoomComponent`, mesmo padrão que `bossBuilder`/`isBossFloor` já usa.
  /// `null` sem slot livre no grupo: a sala fica vazia, sem prompt nem fila
  /// de espera.
  WildCreatureNpc? _buildWildCreature(Vector2 position) {
    final slotVazio = companionCreatures.indexWhere((c) => c == null);
    if (slotVazio == -1) return null;

    final possiveis = CreatureRegistry.all
        .where((c) => !companionCreatures.any((owned) => owned?.id == c.id))
        .toList();
    if (possiveis.isEmpty) return null;

    final sorteada = possiveis[_wildRandom.nextInt(possiveis.length)];
    return WildCreatureNpc(position: position, creatureData: sorteada);
  }

  /// Chamado por `WildCreatureNpc` quando o jogador encosta nela. Entra no
  /// banco com vida cheia — o jogador troca pra ela quando quiser, pelo
  /// retrato. Devolve `false` só em caso de corrida rara (grupo já se
  /// preencheu entre a sala nascer e o toque acontecer).
  bool recrutarCriaturaSelvagem(CreatureData creature) {
    final slotVazio = companionCreatures.indexWhere((c) => c == null);
    if (slotVazio == -1) return false;

    companionCreatures[slotVazio] = creature;
    companionSavedHealth[slotVazio] = creature.stats.maxHp;
    companionPocketed[slotVazio] = true;
    companionXp[slotVazio] = 0.0;
    companionEvoluida[slotVazio] = false;
    return true;
  }

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

  /// Overlay pra reabrir quando o jogador sai de 'Settings' — a tela é
  /// compartilhada entre o menu principal e o menu de pausa (ver
  /// [PauseMenuOverlay] e [MainMenuOverlay]), então o "VOLTAR" precisa saber
  /// pra qual dos dois voltar. Quem abre 'Settings' escreve aqui antes.
  String settingsReturnOverlay = 'MainMenu';

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
  Color backgroundColor() => UiTheme.screenBackground;

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

    // Mesmo tratamento pros efeitos sonoros: `main.dart` já disparou isto
    // sem esperar (só pra começar cedo, antes do GameWidget existir), mas o
    // jogo em si só é dado como carregado depois que os sons também
    // estiverem prontos — `preload()` é "single-flight", então não recarrega
    // nada, só espera terminar.
    await GameAudio.instance.preload();

    // 2. Configura a Câmera (Resolução Fixa: 160 x 144). Não depende do
    // jogador, então já pode ser montada aqui — a run em si só começa
    // quando o jogador escolhe uma criatura no CreatureSelectOverlay.
    gameCamera = CameraComponent.withFixedResolution(
      width: RoomComponent.roomWidth,
      height: RoomComponent.roomHeight,
      world: dungeonWorld,
    );
    gameCamera.viewfinder.position = Vector2(
      RoomComponent.roomWidth / 2,
      RoomComponent.roomHeight / 2,
    );
    add(gameCamera);
    add(GameboyBezel(camera: gameCamera));

    pauseEngine();
  }

  /// Começa uma run nova com a criatura escolhida no seletor. Pode ser
  /// chamado mais de uma vez: voltar ao menu e escolher outra criatura
  /// derruba a run anterior (jogador e dungeon) e monta tudo de novo.
  void startRun(CreatureData creature) {
    // Varredura explícita por tipo além do loop genérico abaixo: encontramos
    // um caso (Game Over → "Menu Principal") em que dois `startRun` corriam
    // em sequência com o motor pausado, e o `Player` da run anterior
    // sobrevivia — o joystick é uma instância única compartilhada por todo
    // `Player`, então dois montados ao mesmo tempo se moviam juntos.
    for (int i = 0; i < maxCompanions; i++) {
      companionCreatures[i] = null;
      companionPocketed[i] = false;
      companionSavedHealth[i] = 0.0;
      companionXp[i] = 0.0;
      companionEvoluida[i] = false;
    }
    companionAtivoIndex = 0;
    dungeonWorld.children.whereType<Player>().toList().forEach(
      (p) => p.removeFromParent(),
    );

    for (final child in dungeonWorld.children.toList()) {
      child.removeFromParent();
    }
    loadedRooms.clear();

    player = Player(moveJoystick: moveJoystick, creatureData: creature);
    _runStarted = true;
    player.position = Vector2(
      RoomComponent.roomWidth / 2,
      RoomComponent.roomHeight / 2,
    );
    dungeonWorld.add(player);

    companionCreatures[0] = creature;
    companionPocketed[0] = false;

    // Run nova: volta pro primeiro andar e sorteia o boss que espera no
    // andar final desta run.
    currentLevel = 1;
    currentFloor = 1;
    runBoss = BossRegistry.sortearPendente(_bossRandom);

    final generator = DungeonGenerator(
      maxRooms: 12,
    ); // Gera uma dungeon com 12 salas
    mapData = generator.generate();

    // Percorre todos os dados de salas criados pelo algoritmo
    for (var roomData in mapData.values) {
      // Cria o componente visual e o adiciona ao mundo
      final room = RoomComponent(
        roomData,
        player: player,
        currentLevel: currentLevel,
        floor: currentFloor,
        bossBuilder: isBossFloor ? _buildRunBoss : null,
        wildCreatureBuilder: currentFloor == andaresPorBoss - 1
            ? _buildWildCreature
            : null,
      );
      loadedRooms['${roomData.x},${roomData.y}'] = room;
      dungeonWorld.add(room);
    }

    currentRoomIndex = Vector2.zero();
    gameCamera.viewfinder.position = Vector2(
      RoomComponent.roomWidth / 2,
      RoomComponent.roomHeight / 2,
    );

    // Remove HUD/minimapa de uma run anterior, se houver, antes de recriar.
    gameCamera.viewport.children.whereType<Hud>().toList().forEach(
      (h) => h.removeFromParent(),
    );
    gameCamera.viewport.children.whereType<MinimapHud>().toList().forEach(
      (m) => m.removeFromParent(),
    );
    // Barra de boss de uma run anterior: o boss dela já foi removido junto com
    // o mundo, mas a barra vive na viewport e sobraria órfã.
    gameCamera.viewport.children.whereType<BossHealthBar>().toList().forEach(
      (b) => b.removeFromParent(),
    );
    gameCamera.viewport.children.whereType<BlindOverlay>().toList().forEach(
      (c) => c.removeFromParent(),
    );

    final hud = Hud(
      player: player,
      companionCreatureAt: (slot) => companionCreatures[slot],
      companionPocketFractionAt: (slot) => companionPocketFraction(slot),
      isCompanionAtivo: (slot) => slot == companionAtivoIndex,
      onTapCompanionSlot: onTapCompanionSlot,
    );
    gameCamera.viewport.add(hud);

    gameCamera.viewport.add(BlindOverlay(player: player, camera: gameCamera));

    minimapHud = MinimapHud(
      mapData: mapData,
      getCurrentLogicalRoom: () {
        return Vector2(
          currentRoomIndex.x + dungeonGridOrigin,
          currentRoomIndex.y + dungeonGridOrigin,
        );
      },
      position: Vector2(RoomComponent.roomWidth - 1, 1),
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
    boss.ehBoss = true;
    // A barra se auto-remove quando o boss sai do mundo, então é só somar.
    gameCamera.viewport.add(
      BossHealthBar(boss: boss, nome: option.nome(buildContext!)),
    );
    return boss;
  }

  /// ATALHO DE TESTE (F1): joga um boss na frente do jogador sem precisar
  /// chegar no andar final. Sempre o primeiro do registry, pra ser
  /// determinístico durante o ajuste de números.
  void _spawnTestBoss() {
    if (!_runStarted) return;

    final option = BossRegistry.all.first;
    final boss = option.builder(player.position + Vector2(0, -40), player);
    boss.ehBoss = true;
    dungeonWorld.add(boss);
    gameCamera.viewport.add(
      BossHealthBar(boss: boss, nome: option.nome(buildContext!)),
    );
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // <-- MUDOU AQUI
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f1) {
      _spawnTestBoss();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
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

  /// Pré-processa toda combinação caminho+cores que o jogo pode desenhar em
  /// pleno jogo, pra que a PRIMEIRA vez que ela aparecer (primeiro inimigo
  /// de uma espécie nova numa sala, primeira captura de uma criatura nova,
  /// primeiro tiro de uma habilidade) não trave gerando a textura na hora.
  /// `PaletteSwapper` já cacheia por caminho+cores (ver `_keyFor`); isto só
  /// garante que o cache já está quente ANTES da run começar.
  ///
  /// Três blocos:
  /// 1. Sprites genéricos (tiros/itens padrão, sem depender de criatura).
  /// 2. Combinações fixas: os 5 ícones de condição, o alerta de ataque
  ///    (`Enemy.spawnAlerta`), e as habilidades/passivas cuja arte usa
  ///    cor de uma criatura específica só (`Ericar` é sempre a cor do
  ///    Ouriço, por exemplo) — não dá pra derivar isso do `CreatureRegistry`
  ///    genericamente, porque `Ability`/`Passive` não expõem sprite/cor como
  ///    dado; precisa ser mantido à mão quando a arte de uma habilidade
  ///    mudar (ver comentário de cada entrada).
  /// 3. Um laço sobre as 16 criaturas do registro: cada uma aparece em até
  ///    três formas visuais distintas (companion — sem `whiteReplacement`;
  ///    inimigo/boss e escudo passivo do treinador — com
  ///    `whiteReplacement: Palette.branco`), e as três precisam do próprio
  ///    cache, mesmo caminho+cores gerando chaves diferentes por causa do
  ///    branco. Autossuficiente: uma 17ª criatura no registry já entra
  ///    sozinha, sem editar esta função.
  Future<void> _preloadCombatSprites() async {
    final warmUps = <Future<ui.Image>>[
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

      // --- Ícones de condição (ConditionIcons) — 5 combinações fixas,
      // iguais pra qualquer inimigo. Sem preload, o primeiro inimigo
      // atordoado/envenenado/queimado/lento/cego da run travava um pouco.
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/stun.png',
        lightGrayReplacement: Palette.cinza,
        darkGrayReplacement: Palette.laranja,
        whiteReplacement: Palette.branco,
      ),
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/poison.png',
        lightGrayReplacement: Palette.verde,
        darkGrayReplacement: Palette.amarelo,
        whiteReplacement: Palette.branco,
      ),
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/fogo.png',
        lightGrayReplacement: Palette.laranja,
        darkGrayReplacement: Palette.vermelho,
        whiteReplacement: Palette.branco,
      ),
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/lento.png',
        lightGrayReplacement: Palette.azul,
        darkGrayReplacement: Palette.indigo,
        whiteReplacement: Palette.branco,
      ),
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/cego.png',
        lightGrayReplacement: Palette.cinza,
        darkGrayReplacement: Palette.cinzaEsc,
        whiteReplacement: Palette.branco,
      ),
      // Alerta antes do inimigo atacar (Enemy.spawnAlerta)
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/exclamacao.png',
        lightGrayReplacement: Palette.indigo,
        darkGrayReplacement: Palette.vermelho,
        whiteReplacement: Palette.branco,
      ),

      // --- Projéteis de habilidade/passiva com cor fixa (não derivada de
      // `creatureData` na hora do disparo). Mantido à mão — ver comentário
      // do método.
      // Roedor de Fogo — RajadaDeBrasa
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/fogo2.png',
        lightGrayReplacement: Palette.vermelho,
        darkGrayReplacement: Palette.laranja,
      ),
      // Tartaruga de Planta / Slime de Planta — CuspeDeSemente / CuspeVenenoso
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/proj1.png',
        lightGrayReplacement: Palette.verde,
        darkGrayReplacement: Palette.verdeEsc,
      ),
      // Sapo de Água — BolaDagua
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/proj1.png',
        lightGrayReplacement: Palette.azul,
        darkGrayReplacement: Palette.azulEsc,
      ),
      // Ave Elétrica — BicoEletrico
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/proj2.png',
        lightGrayReplacement: Palette.amarelo,
        darkGrayReplacement: Palette.laranja,
      ),
      // Tornado de Fogo — SocoFlamejante
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/soco.png',
        lightGrayReplacement: Palette.vermelho,
        darkGrayReplacement: Palette.roxoEsc,
      ),
      // Cobra de Água — JatoAquatico
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/proj1.png',
        lightGrayReplacement: Palette.azul,
        darkGrayReplacement: Palette.royal,
      ),
      // Grilo Elétrico — ChoqueEletrico
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/raio.png',
        lightGrayReplacement: Palette.amarelo,
        darkGrayReplacement: Palette.laranja,
      ),
      // Pinguim de Água — TiroDeGelo
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/proj1.png',
        lightGrayReplacement: Palette.azul,
        darkGrayReplacement: Palette.indigo,
      ),
      // Toco de Madeira — FolhasNavalha
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/folha.png',
        lightGrayReplacement: Palette.verde,
        darkGrayReplacement: Palette.verdeEsc,
      ),
      // Tornado de Fogo — TornadoResidual (passiva)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/tornado.png',
        lightGrayReplacement: Palette.vermelho,
        darkGrayReplacement: Palette.laranja,
      ),
      // Slime de Planta — PecoenhaReflexiva (passiva)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/bolaGrande.png',
        lightGrayReplacement: Palette.verde,
        darkGrayReplacement: Palette.verdeEsc,
      ),

      // --- Habilidades/passivas cuja arte usa a cor da PRÓPRIA criatura
      // (`user.creatureData.corClara/corEscura` no código da habilidade) —
      // a combinação abaixo é a cor real de quem usa cada uma, não um valor
      // genérico.
      // Ouriço Elétrico — Ericar
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/raio.png',
        lightGrayReplacement: CreatureRegistry.ouricoEletrico.corClara,
        darkGrayReplacement: CreatureRegistry.ouricoEletrico.corEscura,
      ),
      // Caranguejo Ermitão de Fogo — BaforadaDeCinzas
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/nuvemP.png',
        lightGrayReplacement: CreatureRegistry.caranguejoErmitao.corClara,
        darkGrayReplacement: CreatureRegistry.caranguejoErmitao.corEscura,
      ),
      // Caranguejo Ermitão de Fogo — FumacaAoLacar (passiva)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/nuvem.png',
        lightGrayReplacement: CreatureRegistry.caranguejoErmitao.corClara,
        darkGrayReplacement: CreatureRegistry.caranguejoErmitao.corEscura,
      ),
      // Leão Elétrico — EstocadaRelampago
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/proj2.png',
        lightGrayReplacement: CreatureRegistry.leaoEletrico.corClara,
        darkGrayReplacement: CreatureRegistry.leaoEletrico.corEscura,
      ),
    ];

    // --- Uma vez por criatura do registro: as três formas visuais que ela
    // pode assumir em jogo (ver doc do método).
    for (final c in CreatureRegistry.all) {
      // Inimigo comum/boss (Enemy.onLoad) e escudo passivo do treinador
      // (Player.onLoad) — as duas usam `whiteReplacement: Palette.branco`,
      // então compartilham exatamente esta chave de cache.
      warmUps.add(
        PaletteSwapper.createSwappedImage(
          imagePath: c.spritePath,
          lightGrayReplacement: c.corClara,
          darkGrayReplacement: c.corEscura,
          whiteReplacement: Palette.branco,
        ),
      );
      warmUps.add(
        PaletteSwapper.createSwappedImage(
          imagePath: 'projeteis/bolha.png',
          lightGrayReplacement: c.corClara,
          darkGrayReplacement: c.corEscura,
          whiteReplacement: Palette.branco,
        ),
      );
      // Sprite do próprio `Player` (ver `Player._montarVisualEHitbox`) — sem
      // `whiteReplacement`, chave diferente da forma inimigo/escudo acima.
      // Cobre tanto a criatura inicial (slot 0) quanto qualquer troca em
      // pleno jogo pra uma espécie ainda não vista na run (recrutada na sala
      // da escada, ver PIVOT_CONTROLE_DIRETO.md §5) — sem isso, a PRIMEIRA
      // troca pra uma criatura nova geraria a textura em pleno combate.
      warmUps.add(
        PaletteSwapper.createSwappedImage(
          imagePath: c.spritePath,
          lightGrayReplacement: c.corClara,
          darkGrayReplacement: c.corEscura,
        ),
      );
    }

    // Formas evoluídas (ver PIVOT_EVOLUCAO): só a forma `Player` — uma
    // evolução nunca aparece como inimigo/boss nem escudo passivo de outra
    // criatura, só substitui o sprite da ativa em pleno jogo. Sem isso, a
    // PRIMEIRA evolução da run geraria a textura em pleno combate.
    for (final evoluida in [
      CreatureRegistry.roedorFogoEvo,
      CreatureRegistry.tartarugaPlantaEvo,
      CreatureRegistry.sapoAguaEvo,
      CreatureRegistry.aveEletricaEvo,
    ]) {
      warmUps.add(
        PaletteSwapper.createSwappedImage(
          imagePath: evoluida.spritePath,
          lightGrayReplacement: evoluida.corClara,
          darkGrayReplacement: evoluida.corEscura,
        ),
      );
    }

    await PaletteSwapper.warmUp(warmUps);
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

    switch (_controlScheme) {
      case ControlScheme.botoes:
        _setupActionButtons();
      case ControlScheme.gestos:
        _setupGestureControls();
    }

    addAll(_abilityControls);
  }

  /// Metade direita da tela como área de gesto, sem botão desenhado
  /// (PIVOT_CONTROLE_DIRETO.md §2.7): toque parado e mantido = habilidade A
  /// (segura enquanto o cooldown zera, mesmo padrão do esquema de botões);
  /// arrastar pra cima = habilidade B (dispara uma vez por arraste — sem
  /// hold contínuo aqui, limitação conhecida e aceitável do gesto, ver o
  /// doc); arrastar pra baixo = esquiva.
  void _setupGestureControls() {
    _abilityControls.add(
      GestureActionArea(
        onAbility1HoldChanged: (active) {
          if (_runStarted) player.touchHoldAbility1 = active;
        },
        onAbility2: () {
          if (_runStarted) player.dispararAbility2();
        },
        onDodge: () {
          if (_runStarted) player.dodge();
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
    final raio = _isDesktop ? 22.0 : 50.0;
    const double margemEsquerda = 16.0;
    const double gap = 10.0;

    for (int i = 0; i < 2; i++) {
      add(
        ConsumableSlotButton(
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
        ),
      );
    }
  }

  void _setupActionButtons() {
    // Três botões: habilidade A, habilidade B, esquiva (PIVOT_CONTROLE_DIRETO.md
    // §2.7) — controle direto de novo, sem override de companion nenhum.
    //
    // Raio 50 (100dp de diâmetro) no mobile é o piso de alvo de toque do
    // Material — com 18 (36dp) o botão ficava menor que o mínimo recomendado.
    final buttonRadius = (_isDesktop ? 22.0 : 50.0);

    // Margens DERIVADAS do raio, não fixas: garante que os três nunca se
    // sobrepõem em X, não importa o valor de buttonRadius.
    const double edgeMarginX = 20;
    const double edgeMarginY = 35;
    const double gap = 10;
    final double marginRightA = edgeMarginX;
    final double marginRightB = edgeMarginX + buttonRadius * 2 + gap;
    final double marginBottomC = edgeMarginY + buttonRadius * 2 + gap;

    // Habilidade A — segurar dispara enquanto o cooldown permitir, mesmo
    // padrão do teclado (`Player.touchHoldAbility1`).
    _abilityControls.add(
      AbilityButton(
        radius: buttonRadius,
        tipo: () => _runStarted
            ? player.creatureData.ability1.tipo
            : AbilityTipo.ataque,
        baseColor: Palette.cinza.withAlpha(255),
        pressedColor: Palette.cinza.withAlpha(140),
        pointerTracker: pointerTracker,
        margin: EdgeInsets.only(right: marginRightB, bottom: edgeMarginY),
        onPressedChanged: (pressed) {
          if (_runStarted) player.touchHoldAbility1 = pressed;
        },
      ),
    );

    // Habilidade B — mesmo padrão da A.
    _abilityControls.add(
      AbilityButton(
        radius: buttonRadius,
        tipo: () => _runStarted
            ? player.creatureData.ability2.tipo
            : AbilityTipo.ataque,
        baseColor: Palette.cinza.withAlpha(255),
        pressedColor: Palette.cinza.withAlpha(140),
        pointerTracker: pointerTracker,
        margin: EdgeInsets.only(right: marginRightA, bottom: marginBottomC),
        onPressedChanged: (pressed) {
          if (_runStarted) player.touchHoldAbility2 = pressed;
        },
      ),
    );

    // Esquiva pessoal, não uma habilidade de criatura — ver `Player.dodge`.
    // Sem cooldown desenhado aqui (a barra própria da esquiva vive embaixo
    // do sprite do jogador, ver `Player.render`).
    /* _abilityControls.add(
      AbilityButton(
        radius: buttonRadius,
        tipo: () => AbilityTipo.esquiva,
        baseColor: Palette.cinza.withAlpha(255),
        pressedColor: Palette.cinza.withAlpha(140),
        pointerTracker: pointerTracker,
        margin: EdgeInsets.only(right: marginRightA, bottom: marginBottomC),
        onPressedChanged: (pressed) {
          if (pressed) player.dodge();
        },
      ),
    );
    */
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

  /// Fração de vida FALTANDO no banco (0 = vida cheia, 1 = zerada) — mesma
  /// convenção visual que `AbilityCooldownIndicator` usa (cinza cheio =
  /// "não pronto"). Sem cura passiva, esse valor é estático: só muda quando
  /// a criatura entra/sai do banco, não com o tempo. Fora do banco, 0 — nada
  /// pra desenhar.
  double companionPocketFraction(int slot) {
    if (!companionPocketed[slot]) return 0.0;
    final creature = companionCreatures[slot];
    if (creature == null || creature.stats.maxHp <= 0) return 0.0;
    return (1 - companionSavedHealth[slot] / creature.stats.maxHp).clamp(
      0.0,
      1.0,
    );
  }

  // NOVO MÉTODO: Limpa e recria a fase!
  void nextLevel() {
    // 1. LIMPEZA TOTAL (O "faxineiro")
    // Remove salas velhas, tiros perdidos, itens no chão... tudo, MENOS o
    // jogador (que precisa atravessar de andar) — o grupo inteiro é só dado
    // (`companionCreatures`), não componente montado, então não há mais nada
    // além do `Player` pra preservar aqui.
    GameAudio.instance.play(Sfx.stairs);
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

    if (currentFloor > numFloors) {
      currentLevel++;
      currentFloor = 1;
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
        floor: currentFloor,
        bossBuilder: isBossFloor ? _buildRunBoss : null,
        wildCreatureBuilder: currentFloor == andaresPorBoss - 1
            ? _buildWildCreature
            : null,
      );
      loadedRooms['${roomData.x},${roomData.y}'] = room;
      dungeonWorld.add(room);
    }

    // 3. REPOSICIONAMENTO DO JOGADOR E CÂMERA
    // Volta o jogador para o centro lógico da fase (Sala Inicial)
    player.position = Vector2(
      RoomComponent.roomWidth / 2,
      RoomComponent.roomHeight / 2,
    );
    currentRoomIndex = Vector2.zero();

    // Dá um "corte seco" na câmera de volta para o início
    gameCamera.viewfinder.position = Vector2(
      RoomComponent.roomWidth / 2,
      RoomComponent.roomHeight / 2,
    );

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

  /// Empurra o jogador de volta pro interior da sala trancada. Trabalha na
  /// hitbox dos pés, a mesma que as paredes bloqueiam, e usa a espessura de
  /// parede (16px) como borda.
  void _prendeJogadorNaSala(
    double roomLeft,
    double roomTop,
    double roomRight,
    double roomBottom,
  ) {
    const double parede = 16.0;
    final pes = player.physicsHitbox.toAbsoluteRect();

    double dx = 0;
    double dy = 0;

    if (pes.left < roomLeft + parede) {
      dx = (roomLeft + parede) - pes.left;
    } else if (pes.right > roomRight - parede) {
      dx = (roomRight - parede) - pes.right;
    }

    if (pes.top < roomTop + parede) {
      dy = (roomTop + parede) - pes.top;
    } else if (pes.bottom > roomBottom - parede) {
      dy = (roomBottom - parede) - pes.bottom;
    }

    if (dx == 0 && dy == 0) return;

    player.position += Vector2(dx, dy);
    if (dx != 0) player.velocity.x = 0;
    if (dy != 0) player.velocity.y = 0;
  }

  void _checkCameraTransition() {
    // `physicsHitbox` só existe depois do onLoad do jogador (que espera as
    // trocas de paleta); até lá não há o que checar.
    if (!player.isLoaded) return;

    // Sem essa guarda, uma transição já em andamento (`player.naoMove`,
    // câmera ainda no `MoveToEffect` de 0.4s) não impedia esta função de
    // rodar de novo todo frame e achar `currentRoomIndex` de novo do lado
    // errado da fronteira (empurrão de parede/obstáculo perto da porta, ou
    // qualquer reposicionamento no meio do pan) — cada chamada empilhava
    // outro `MoveToEffect` competindo com o anterior e trocava
    // `currentRoomIndex` de novo, e de novo, sem nunca assentar: minimapa
    // alternando entre as duas salas, jogador travado sem controle porque
    // `naoMove` nunca volta a `false` de vez. Uma transição por vez, ponto.
    if (player.naoMove) return;

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

    // Sala trancada não deixa passar, ponto: nem troca de sala, nem sair pela
    // borda. Recusar só a troca não bastava — o jogador continuava andando
    // pra fora com a câmera parada, porque a resolução de colisão empurra
    // pelo lado MAIS PERTO: quem afunda mais da metade dos 16px da parede é
    // cuspido pro lado de fora em vez de voltar pra dentro. Com a sala
    // trancada a regra é dura, então prendemos os pés no interior dela.
    final salaAtual =
        loadedRooms['${currentRoomIndex.x.toInt() + dungeonGridOrigin},${currentRoomIndex.y.toInt() + dungeonGridOrigin}'];
    if (salaAtual != null && salaAtual.isLocked) {
      _prendeJogadorNaSala(roomLeft, roomTop, roomRight, roomBottom);
      return;
    }

    // O gatilho lê a hitbox de física (os pés), não `player.position`. Eram
    // duas referências diferentes: a porta bloqueia os pés, mas a troca de
    // sala olhava o centro do componente, que fica `hitboxSize.y / 2` acima
    // dos pés. Em criaturas altas sobrava só ~3px entre "a porta empurra" e
    // "a sala troca", e qualquer frame mais longo pulava essa margem — o
    // jogador atravessava a porta trancada. Com os pés dos dois lados da
    // conta, a folga vira 8px fixos pra qualquer criatura.
    final pes = player.physicsHitbox.toAbsoluteRect();

    if (pes.right > roomRight - threshold) {
      newRoomX++;
      transitioned = true;
    } else if (pes.left < roomLeft + threshold) {
      newRoomX--;
      transitioned = true;
    } else if (pes.bottom > roomBottom - threshold) {
      newRoomY++;
      transitioned = true;
    } else if (pes.top < roomTop + threshold) {
      newRoomY--;
      transitioned = true;
    }

    if (transitioned) {
      player.naoMove = true;

      // Empurrão derivado da borda TRASEIRA do `physicsHitbox`, não uma
      // constante fixa. A constante (22px) só levava o CENTRO do jogador pra
      // além da fronteira — a borda de trás (a que importa: é ela que o
      // próximo `_checkCameraTransition` compara contra o threshold da sala
      // nova) ficava a `hitboxSize.x` de distância além disso. Toda criatura
      // com hitbox largo o bastante (>6px, ou seja, qualquer uma) reentrava
      // no threshold assim que o congelamento acabava e revertia a troca —
      // o jogador ficava entrando e saindo da mesma porta sem fim. Só não
      // aparecia numa sala nova porque `onPlayerEnter` tranca a sala e
      // `_prendeJogadorNaSala` mascara o ping-pong; numa sala já limpa
      // (`isLocked` nunca liga) o bug ficava visível.
      const double margem = 4.0;

      if (newRoomX > currentRoomIndex.x) {
        player.position.x += (roomRight + threshold + margem) - pes.left;
      } else if (newRoomX < currentRoomIndex.x) {
        player.position.x -= pes.right - (roomLeft - threshold - margem);
      } else if (newRoomY > currentRoomIndex.y) {
        player.position.y += (roomBottom + threshold + margem) - pes.top;
      } else if (newRoomY < currentRoomIndex.y) {
        player.position.y -= pes.bottom - (roomTop - threshold - margem);
      }

      currentRoomIndex = Vector2(newRoomX.toDouble(), newRoomY.toDouble());

      int logicalX = newRoomX + dungeonGridOrigin;
      int logicalY = newRoomY + dungeonGridOrigin;
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
          },
        ),
      );
    }
  }
}
