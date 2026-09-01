import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/UI/dynamic_joystick_component.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/capture_lasso_visual.dart';
import 'package:creatures_rogue/game/components/creatures/damageable_by_enemy.dart';
import 'package:creatures_rogue/game/components/creatures/passive.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/effects/movement_animator.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/items/consumable_item.dart';
import 'package:creatures_rogue/game/components/map/dungeon_generator.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/bomb.dart';
import 'package:creatures_rogue/game/components/player/trainer_stats.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:flutter/services.dart';
import '../map/obstacle.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameRef, KeyboardHandler, AbilityUser, DamageableByEnemy {
  final DynamicJoystickComponent moveJoystick;
  final CreatureData creatureData;

  /// Vida, velocidade e escudo do treinador (PIVOT_TREINADOR.md §3.7) — não
  /// vêm mais de `creatureData.stats`, que é da criatura, não dele.
  /// `creatureData` continua aqui só pelo visual (sprite/hitbox/animação):
  /// o treinador ainda não tem sprite próprio, gap conhecido e fora desta
  /// rodada, não coberto por §3.7.
  final TrainerStats stats;

  // Componente visual único, animado por transformação (escala/flip), não por troca de frame.
  late final SpriteComponent visual;
  late final Vector2 _visualBasePosition;
  late final MovementAnimator _moveAnimator;

  late final SpriteComponent circDir;

  // Bolha desenhada por cima do player enquanto uma habilidade defensiva
  // (Bolha Protetora, Casco Fechado) está com o efeito ativo.
  // `shieldVisualActive` vem de AbilityUser.
  late final SpriteComponent shieldVisual;

  // --- NOVAS VARIÁVEIS DE COLISÃO ---
  late RectangleHitbox playerHitbox;  // Colisor de Combate (Corpo)
  late RectangleHitbox physicsHitbox; // Colisor de Física (Pés/Sombra)

  final Vector2 _keyboardMove = Vector2.zero();

  double maxHealth;
  double currentHealth;

  /// Tempo desde o último golpe realmente recebido (resetado em
  /// `takeDamage`, mesmo ponto que dispara retaliação) — usado por passivas
  /// que observam o tempo passando (ex.: Bolha Autônoma, do Sapo de Água).
  double _tempoSemApanhar = 0.0;
  double get tempoSemApanhar => _tempoSemApanhar;

  double _invulnerabilityTimer = 0.0;
  final double _invulnerabilityDuration = 1.5;

  /// Escudo passivo derivado da defesa: uma segunda barra que absorve dano
  /// antes do HP e regenera sozinha com o tempo. Tamanho e taxa de regen são
  /// mutáveis (não final) porque upgrades e itens futuros vão alterá-los
  /// durante a run.
  double shieldMax;
  double shield;
  double shieldRegenAmount = 1.0;
  double shieldRegenInterval = 5.0;
  double _shieldRegenTimer = 0.0;

  int bombsAmount = 3;

  /// Moedas da run, gastas nos balcões da loja (ver ShopStand). Zeram junto
  /// com o Player, ou seja, a cada run nova.
  int coins = 0;

  /// Inventário de itens de uso único: dois slots, cada um com no máximo um
  /// item. `null` = vazio. Uma lista de tamanho fixo em vez de dois campos
  /// porque os botões da tela são indexados (ver ConsumableSlotButton).
  final List<ConsumableType?> slots = [null, null];

  // --- Multiplicadores de upgrade da run ---
  // Ficam aqui, e não em BaseStats, porque BaseStats é `const` (compartilhado
  // entre todas as instâncias da criatura). Mesmo padrão do `lentidaoFator`
  // logo abaixo: o valor base nunca muda, quem multiplica é o getter.
  double velMult = 1.0;

  /// Dano do jogador. É `static` porque quem multiplica é o próprio projétil /
  /// explosão no momento do acerto (ver `Projectile.onCollision`), e eles não
  /// têm referência ao Player. Aplicar nas 34 habilidades seria 34 edições;
  /// aqui são duas. Zera no construtor, ou seja, a cada run nova.
  static double danoMult = 1.0;

  Vector2 velocity = Vector2.zero();
  Vector2 knockbackVelocity = Vector2.zero();
  Vector2 plrDir = Vector2(0,1);

  double get maxSpeed => stats.speed * lentidaoFator * velMult;

  /// Lentidão e cegueira são as únicas condições que atingem o jogador — DoT
  /// fica só do lado dos inimigos, que têm os ícones de condição pra mostrar.
  /// Aqui a leitura vem do próprio movimento e da vinheta (ver BlindOverlay).
  double lentidaoTimer = 0.0;
  double lentidaoFator = 1.0;
  double cegoTimer = 0.0;
  double cegoDuracaoInicial = 0.0;
  final double acceleration = 100.0;
  final double friction = 500.0;

  /// `lockedAb1Direction`/`lockedAb2Direction` (exigidos por `AbilityUser`)
  /// não são mais computados aqui — o treinador não executa mais habilidade
  /// de criatura nenhuma (ver PIVOT_TREINADOR.md §2.1: os botões viram
  /// override do `Companion` ativo). Ficam parados no valor inicial, inertes.
  Vector2 lockedAb1Direction = Vector2(0,1);
  Vector2 lockedAb2Direction = Vector2(0,1);

  bool naoMove = false;

  // Ganchos usados pelas habilidades das criaturas (shieldVisualActive,
  // speedLocked, shieldHits, damageReduction, refleteProjetil, retalia*)
  // vêm de AbilityUser — não redeclarar aqui. Neutros pra sempre no
  // treinador agora que só o Companion executa habilidade.

  bool isAirborne = false;

  // --- Salto genérico (ex.: Jogada de Corpo) — mesma curva visual do
  // JumpMovement dos inimigos: sobe em arco e estica no ar. Enquanto
  // pulando, substitui o controle normal e o MovementAnimator (os dois
  // escrevem visual.position.y/scale, e disputariam o mesmo canal).
  bool _pulando = false;
  double _puloTimer = 0.0;
  double _puloDuracao = 0.3;
  double _puloAltura = 16.0;
  Vector2 _puloDirecao = Vector2.zero();
  double _puloVelocidade = 0.0;
  VoidCallback? _puloAoAterrissar;

  /// Salta na direção [direction], percorrendo [distance] px ao longo de
  /// [duration]s. Com [direction] zero (sem mira/movimento), pula no lugar
  /// — mesma curva de altura, sem deslocamento horizontal. [onLand] roda no
  /// frame em que os pés tocam o chão.
  void startJump({
    required Vector2 direction,
    required double distance,
    required double duration,
    double height = 16.0,
    VoidCallback? onLand,
  }) {
    _pulando = true;
    _puloTimer = 0.0;
    _puloDuracao = duration;
    _puloAltura = height;
    _puloAoAterrissar = onLand;
    velocity.setZero();

    if (direction.length == 0) {
      // Pulo vertical: sobe e desce no lugar, mantendo a direção que já
      // estava olhando.
      _puloDirecao = Vector2.zero();
      _puloVelocidade = 0.0;
      return;
    }

    _puloDirecao = direction.normalized();
    _puloVelocidade = distance / duration;

    if (_puloDirecao.x < 0 && !visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    } else if (_puloDirecao.x > 0 && visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    }
  }

  void _updateJump(double dt) {
    _puloTimer += dt;
    position += _puloDirecao * _puloVelocidade * dt;

    final progress = (_puloTimer / _puloDuracao).clamp(0.0, 1.0);
    final zOffset = 4 * _puloAltura * progress * (1 - progress);
    visual.position.y = _visualBasePosition.y - zOffset;

    final flip = visual.scale.x.isNegative ? -1.0 : 1.0;
    visual.scale = Vector2(0.9 * flip, 1.1); // estica no ar, igual ao inimigo

    if (_puloTimer >= _puloDuracao) {
      _pulando = false;
      visual.position.y = _visualBasePosition.y;
      visual.scale = Vector2(flip, 1.0);
      final aoAterrissar = _puloAoAterrissar;
      _puloAoAterrissar = null;
      aoAterrissar?.call();
    }
  }

  /// Reaplicar renova a duração e fica com o fator mais forte — nunca
  /// multiplica um sobre o outro, senão duas nuvens seguidas travam o jogador.
  void aplicarLentidao(double duracao, {double fator = 0.5}) {
    if (duracao > lentidaoTimer) lentidaoTimer = duracao;
    if (fator < lentidaoFator) lentidaoFator = fator;
  }

  void aplicarCegueira(double duracao) {
    if (duracao <= cegoTimer) return;
    cegoTimer = duracao;
    cegoDuracaoInicial = duracao;
  }

  void grantInvulnerability(double seconds) {
    if (seconds > _invulnerabilityTimer) _invulnerabilityTimer = seconds;
  }

  /// Ação pessoal do treinador — não passa por `Ability`/`Companion` nenhum.
  /// Resposta direta ao playtest da fase 3: sem isso, os dois botões de
  /// habilidade agiam sobre a criatura e o treinador não tinha propósito
  /// nenhum em combate (ver PIVOT_TREINADOR.md §2.1). Mesma receita de
  /// `EsquivaBomba`: i-frames mais dash com rastro fantasma.
  double _dodgeCooldown = 0.0;
  static const double _dodgeCooldownMax = 1.1;
  static const double _dodgeDuration = 0.18;
  static const double _dodgeDistance = 30.0;

  /// Duração dos i-frames da esquiva, exposta pra fora — algumas passivas
  /// (ex.: Casco Reflexivo, Rastro Flamejante) agendam efeito pra terminar
  /// junto com a janela de invulnerabilidade, sem duplicar o número aqui.
  double get dodgeIframeDuration => _dodgeDuration;

  /// Passivas das criaturas do grupo (ver `Passive`, PIVOT_TREINADOR.md) —
  /// vale enquanto a criatura estiver no grupo do treinador, capturada ou
  /// não, no bolso ou fora dele. Por isso lê `companionCreatures` (sobrevive
  /// ao bolso), não `companions` (só as fora dele). Sempre recomputado no
  /// uso, nunca cacheado — elimina qualquer ponto de recálculo que
  /// precisaria ser lembrado em captura/dispensa/início de run.
  List<Passive> get passivasAtivas {
    final jogo = game;
    if (jogo is! CreaturesRogueGame) return const [];
    return jogo.companionCreatures
        .whereType<CreatureData>()
        .map((c) => c.passive)
        .toList(growable: false);
  }

  /// Piso do produto de `dodgeCooldownMult` de todas as passivas ativas —
  /// pedido do usuário: passiva repetida (duas ou três criaturas da mesma
  /// espécie) DEVE empilhar, é build válido. Mas sem piso, três cópias de
  /// `ReflexoEletrico` (0.6 cada) dão `0.6³ ≈ 0.22`, ou seja `_dodgeCooldownMax`
  /// (1.1s) vira ~0.24s — menor que a folga entre o fim de uma esquiva e o
  /// início da próxima ser maior que a duração dos i-frames (0.18s), o que
  /// destrava esquiva encadeada = invulnerabilidade quase permanente. Isso
  /// não é "build forte", é o sistema de esquiva inteiro deixando de
  /// importar. 0.3 (30% do cooldown base, ~0.33s) deixa empilhar valer muito
  /// sem zerar a janela de risco. Só no cooldown: `dodgeDistanceMult` não
  /// tem essa classe de risco (não cria invulnerabilidade), fica sem piso.
  static const double _dodgeCooldownMultFloor = 0.3;

  void dodge() {
    if (_dodgeCooldown > 0) return;
    GameAudio.instance.play(Sfx.dash);
    final passivas = passivasAtivas;

    double cooldownMult = 1.0;
    double distanciaMult = 1.0;
    for (final p in passivas) {
      cooldownMult *= p.dodgeCooldownMult;
      distanciaMult *= p.dodgeDistanceMult;
    }
    cooldownMult = cooldownMult < _dodgeCooldownMultFloor ? _dodgeCooldownMultFloor : cooldownMult;
    _dodgeCooldown = _dodgeCooldownMax * cooldownMult;
    grantInvulnerability(_dodgeDuration);

    var dir = velocity.isZero() ? plrDir : velocity.normalized();
    for (final p in passivas) {
      final override = p.direcaoEsquivaOverride(this, dir);
      if (override != null) dir = override;
    }

    GhostEffect.spawnTrail(
      visual: visual,
      add: (g) => parent?.add(g),
      overDuration: _dodgeDuration,
    );
    add(MoveByEffect(dir * _dodgeDistance * distanciaMult, EffectController(duration: _dodgeDuration)));

    for (final p in passivas) {
      p.aoEsquivar(this, dir);
    }
  }

  /// Fração restante do cooldown da esquiva (0 = pronta) — pra HUD desenhar
  /// um indicador, se algum dia precisar de um terceiro.
  double get dodgeCooldownFraction =>
      (_dodgeCooldown / _dodgeCooldownMax).clamp(0.0, 1.0);

  // --- Captura (PIVOT_TREINADOR.md §4, fase 6) ---
  // Também ação pessoal do treinador, fora de `Ability`/`Companion` — a
  // manobra é do jogador segurando o botão e andando, não de criatura
  // nenhuma. "Alvo travado no aperto" (regra 1 do §4.1): resolvido uma vez
  // em [startCapture], nunca reavaliado até soltar/quebrar.
  Enemy? _capturaAlvo;
  double _capturaAnguloAcumulado = 0.0;
  double _capturaUltimoAngulo = 0.0;
  CaptureLassoVisual? _capturaVisual;

  /// Raio da volta em torno do alvo — geometria fixa do §4.1 (24px cabem na
  /// sala com folga pequena, calculado contra `RoomComponent.roomWidth`).
  /// Primeiro corte, não tunado por playtest.
  static const double captureOrbitRadius = 48.0;

  /// Fração de vida máxima abaixo da qual um inimigo pode ser capturado
  /// (§4.2 — segundo portão, também é o que empurra a captura pro fim da
  /// luta). Em 1.0 pra teste (qualquer HP captura, o portão fica desligado
  /// na prática) — pedido explícito, não é o valor final. Voltar pra algo
  /// tipo 0.3 quando validar a manobra em si, senão nunca aperta o
  /// jogador pra deixar o inimigo fraco antes de laçar.
  static const double captureHpFraction = 0.3;

  bool get capturando => _capturaAlvo != null;

  /// Botão de captura pressionado — ver `CaptureButton`/`_setupCaptureButton`.
  void startCapture() {
    if (_capturaAlvo != null) return;

    final alvo = _encontrarAlvoCaptura();
    if (alvo == null) return;

    _capturaAlvo = alvo;
    _capturaAnguloAcumulado = 0.0;
    final delta = position - alvo.position;
    _capturaUltimoAngulo = math.atan2(delta.y, delta.x);
    alvo.enraizarParaCaptura(true);
    for (final p in passivasAtivas) {
      p.aoIniciarLaco(this);
    }

    final visual = CaptureLassoVisual(
      trainer: this,
      alvo: alvo,
      raioAlvo: captureOrbitRadius,
      fracao: () => (_capturaAnguloAcumulado.abs() / (2 * math.pi)).clamp(0.0, 1.0),
    );
    _capturaVisual = visual;
    parent?.add(visual);
  }

  /// Botão solto — regra de quebra #1 do §4.1 ("soltar o botão"). As outras
  /// três quebras (distância, parede, dano) chamam isto também, de dentro de
  /// [_updateCapture] e de [takeDamage].
  void cancelCapture() {
    final alvo = _capturaAlvo;
    if (alvo == null) return;
    alvo.enraizarParaCaptura(false);
    _capturaVisual?.removeFromParent();
    _capturaVisual = null;
    _capturaAlvo = null;
    _capturaAnguloAcumulado = 0.0;
  }

  /// Inimigo mais próximo, capturável (abaixo do limiar de HP, dentro do
  /// alcance, não é boss — §4.4), na sala atual. "Mais próximo" já filtrado
  /// por elegibilidade: travar num alvo que não pode ser capturado não serve
  /// pra nada.
  Enemy? _encontrarAlvoCaptura() {
    final room = currentRoom;
    final inimigos = parent?.children.whereType<Enemy>() ?? const <Enemy>[];
    final alcance = stats.captureRange;

    Enemy? maisProximo;
    double menorDistSq = double.infinity;

    for (final inimigo in inimigos) {
      if (room != null &&
          !room.toAbsoluteRect().contains(
              Offset(inimigo.absolutePosition.x, inimigo.absolutePosition.y))) {
        continue;
      }
      if (inimigo.health > inimigo.maxHealth * captureHpFraction) continue;
      if (inimigo.currentRoom?.data.type == RoomType.boss) continue;

      final distSq = (inimigo.absolutePosition - absolutePosition).length2;
      if (distSq > alcance * alcance) continue;
      if (distSq < menorDistSq) {
        menorDistSq = distSq;
        maisProximo = inimigo;
      }
    }
    return maisProximo;
  }

  /// Há parede entre o treinador e [alvo]? Amostra pontos ao longo do
  /// segmento em vez de testar a caixa delimitadora inteira (que daria falso
  /// positivo com qualquer parede fora da linha, só porque está dentro do
  /// retângulo diagonal entre os dois pontos). Duplica um pedaço pequeno de
  /// `MovementHost.direcaoLivre` em vez de herdar o mixin inteiro — Player
  /// não compartilha o resto das dependências dele (mesmo padrão de
  /// duplicação já aceito entre Player/Enemy/Companion, ver PIVOT_TREINADOR.md
  /// seção 6, "Armadilhas").
  bool _paredeEntreCaptura(Enemy alvo) {
    final room = currentRoom;
    if (room == null) return false;

    final colliders = room.children
        .whereType<PositionComponent>()
        .where((c) => c is WallBarrier || c is Obstacle)
        .toList();
    if (colliders.isEmpty) return false;

    const amostras = 8;
    for (int i = 1; i < amostras; i++) {
      final t = i / amostras;
      final ponto = Offset(
        absolutePosition.x + (alvo.absolutePosition.x - absolutePosition.x) * t,
        absolutePosition.y + (alvo.absolutePosition.y - absolutePosition.y) * t,
      );
      for (final c in colliders) {
        if (c.toAbsoluteRect().contains(ponto)) return true;
      }
    }
    return false;
  }

  /// Acumulação de ângulo (regra 3 do §4.1): delta com sinal do rumo do
  /// treinador em torno da posição ATUAL do alvo (que se move, puxado pro
  /// centro da sala). Retrocesso subtrai em vez de zerar — o alvo se move
  /// sozinho, então exigir uma volta monotônica puniria o jogador por
  /// movimento que não é dele.
  void _updateCapture(double dt) {
    final alvo = _capturaAlvo;
    if (alvo == null) return;

    if (!alvo.isMounted || alvo.health <= 0) {
      cancelCapture();
      return;
    }

    final distancia = (alvo.absolutePosition - absolutePosition).length;
    if (distancia > stats.captureRange) {
      cancelCapture();
      return;
    }
   // if (_paredeEntreCaptura(alvo)) {
    //  cancelCapture();
    //  return;
   // }

    final delta = position - alvo.position;
    if (delta.length == 0) return;
    final anguloAtual = math.atan2(delta.y, delta.x);

    double diff = anguloAtual - _capturaUltimoAngulo;
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    _capturaAnguloAcumulado += diff;
    _capturaUltimoAngulo = anguloAtual;

    if (_capturaAnguloAcumulado.abs() >= 2 * math.pi) {
      _completarCaptura(alvo);
    }
  }

  void _completarCaptura(Enemy alvo) {
    alvo.enraizarParaCaptura(false);
    _capturaVisual?.removeFromParent();
    _capturaVisual = null;
    _capturaAlvo = null;
    _capturaAnguloAcumulado = 0.0;

    final jogo = game;
    if (jogo is CreaturesRogueGame) jogo.capturarCriatura(alvo);
  }

  // --- Indicador da esquiva, embaixo do sprite ---
  // Barra que ENCHE conforme a esquiva recarrega (vazia assim que usa, cheia
  // quando pronta) — oposto do indicador de habilidade da Hud, que ESVAZIA um
  // cinza por cima do ícone. Não tem ícone aqui pra esvaziar, é só uma cor.
  static final Paint _dodgeBarraMoldura = Paint()..color = Palette.preto;
  static final Paint _dodgeBarraFundo = Paint()..color = Palette.cinzaEsc;
  static final Paint _dodgeBarraPreenchimento = Paint()..color = Palette.verde;
  static const double _dodgeBarraLargura = 14.0;
  static const double _dodgeBarraAltura = 2.0;

  void _renderBarraEsquiva(Canvas canvas) {
    final pronto = 1 - dodgeCooldownFraction;
    final left = (size.x - _dodgeBarraLargura) / 2;
    final top = size.y + 4.0;

    canvas.drawRect(
      Rect.fromLTWH(left - 1, top - 1, _dodgeBarraLargura + 2, _dodgeBarraAltura + 2),
      _dodgeBarraMoldura,
    );
    canvas.drawRect(Rect.fromLTWH(left, top, _dodgeBarraLargura, _dodgeBarraAltura), _dodgeBarraFundo);
    if (pronto > 0) {
      canvas.drawRect(
        Rect.fromLTWH(left, top, _dodgeBarraLargura * pronto, _dodgeBarraAltura),
        _dodgeBarraPreenchimento,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderBarraEsquiva(canvas);
  }

  Player({
    required this.moveJoystick,
    required this.creatureData,
    this.stats = TrainerStats.padrao,
  }) : maxHealth = stats.maxHealth,
       currentHealth = stats.maxHealth,
       shieldMax = stats.shieldMax,
       shield = stats.shieldMax,
       super(size: Vector2(16, 16), anchor: Anchor.center) {
    // Um Player novo é exatamente uma run nova (ver `startRun`), então este é
    // o lugar certo pra zerar o multiplicador estático de dano — senão os
    // upgrades da run anterior valeriam na próxima.
    danoMult = 1.0;
  }

  VoidCallback? onDeath;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    //debugMode = true;

    final ui.Image spriteImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'actors/plr.png',
      lightGrayReplacement: Palette.bege,
      darkGrayReplacement: Palette.burgundy,
    );

    _visualBasePosition = Vector2(size.x / 2, size.y);
    _moveAnimator = MovementAnimator(MovementAnimation.caminhada);

    visual = SpriteComponent(
      sprite: Sprite(spriteImage),
      size: size,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition.clone(),
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 1,
    );
    add(visual);

    Vector2 floatOffset = Vector2.zero();

    if(creatureData.moveAnim == MovementAnimation.flutuar){
      isAirborne = true;
      floatOffset = Vector2(0,-4);
    }else{
      isAirborne = false;
    }

    final ui.Image shieldImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'projeteis/bolha.png',
      lightGrayReplacement: creatureData.corClara,
      darkGrayReplacement: creatureData.corEscura,
      whiteReplacement: Palette.branco,
    );
    shieldVisual = SpriteComponent(
      sprite: Sprite(shieldImage),
      size: Vector2.all(24),
      anchor: Anchor.center,
      position: size / 2 + floatOffset,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 5,
    );
    shieldVisual.setOpacity(0.0); // só aparece enquanto shieldVisualActive
    add(shieldVisual);

    // --- 1. COLISOR DE COMBATE (Corpo Inteiro) — tamanho vem da criatura ---
    final hitboxSize = creatureData.hitboxSize;
    playerHitbox = RectangleHitbox(
      size: hitboxSize,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition + floatOffset,
      collisionType: CollisionType.active,
    );
   
    add(playerHitbox);

    // --- 2. COLISOR DE FÍSICA (Metade da altura, fica nos pés) ---
    physicsHitbox = RectangleHitbox(
      size: Vector2(hitboxSize.x, hitboxSize.x * 0.5),
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, hitboxSize.y / 2),
      collisionType: CollisionType.active,
    );
    add(physicsHitbox);

    // --- 3. SOMBRA VISUAL ---
    final shadowPaint = Paint()..color = Palette.preto;

    final shadow = CircleComponent(
      radius: hitboxSize.x / 2,
      anchor: Anchor.center,
      position: _visualBasePosition,//size / 2 + Vector2(0, hitboxSize.y / 2),
      paint: shadowPaint,
      priority: -1,
    )..scale = Vector2(1.2, 0.75);

    add(shadow);

    final ui.Image circDirImg = await Flame.images.load('actors/circDir.png');

    circDir = SpriteComponent(
      sprite: Sprite(circDirImg),
      size: Vector2.all(24),
      anchor: Anchor.center,
      position: _visualBasePosition,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: -2,
    );
    
    add(circDir);

    // playerHitbox.debugMode = true;
    // physicsHitbox.debugMode = true;
    // visual.debugMode = true;
    // shieldVisual.debugMode = true;
    // shadow.debugMode = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Anchor.center: o "chão" (pés) fica meio size.y abaixo do centro.
    priority = ySortPriority(position.y + size.y / 2);

    if (_dodgeCooldown > 0) _dodgeCooldown -= dt;
    _tempoSemApanhar += dt;
    for (final p in passivasAtivas) {
      p.aoAtualizar(this, dt);
    }

    if (lentidaoTimer > 0) {
      lentidaoTimer -= dt;
      if (lentidaoTimer <= 0) lentidaoFator = 1.0;
    }
    if (cegoTimer > 0) cegoTimer -= dt;

    Vector2 moveDelta = moveJoystick.relativeDelta.clone();
    if (moveDelta.isZero() && !_keyboardMove.isZero()) {
      moveDelta = _keyboardMove.normalized();
    }

    if (_invulnerabilityTimer > 0) {
      _invulnerabilityTimer -= dt;
      bool isVisible = (_invulnerabilityTimer * 10).toInt() % 2 == 0;
      visual.setOpacity(isVisible ? 1.0 : 0.2);
    } else {
      visual.setOpacity(1.0);
    }

    shieldVisual.setOpacity(shieldVisualActive ? 1.0 : 0.0);

    if (shield < shieldMax) {
      _shieldRegenTimer += dt;
      if (_shieldRegenTimer >= shieldRegenInterval) {
        _shieldRegenTimer = 0.0;
        shield = (shield + shieldRegenAmount).clamp(0.0, shieldMax);
      }
    }

    if (_pulando) {
      _updateJump(dt);
    } else {
      _updateMovement(dt, moveDelta);
      
      _moveAnimator.update(
        visual: visual,
        basePosition: _visualBasePosition,
        isMoving: !velocity.isZero(),
        horizontalDir: velocity.isZero() ? 0.0 : velocity.normalized().x,
        dt: dt,
      );
    }

    _updateCapture(dt);
  }

  /// Sala onde o player está agora (mesma lógica usada por `Enemy.currentRoom`).
  RoomComponent? get currentRoom {
    final p = parent;
    if (p == null) return null;
    final center = Offset(absolutePosition.x, absolutePosition.y);
    for (final room in p.children.whereType<RoomComponent>()) {
      if (room.toAbsoluteRect().contains(center)) return room;
    }
    return null;
  }

  /// Empurra o jogador para longe de [sourcePosition]. Usado por explosões
  /// de inimigos que repelem (Brado, bote da Cobra).
  void applyKnockback(Vector2 sourcePosition, double force) {
    final direction = (absolutePosition - sourcePosition);
    if (direction.length == 0) return;
    knockbackVelocity = direction.normalized() * force;
  }

  void _updateMovement(double dt, Vector2 moveDelta) {
    // Knockback tem prioridade sobre o controle: enquanto empurrado, o
    // jogador desliza e o input não responde (mesma regra do inimigo).
    if (!knockbackVelocity.isZero()) {
      position += knockbackVelocity * dt;

      final drop = 240.0 * dt; // atrito
      if (knockbackVelocity.length < drop) {
        knockbackVelocity.setZero();
      } else {
        knockbackVelocity -= knockbackVelocity.normalized() * drop;
      }
      velocity.setZero();
      return;
    }

    if(naoMove || speedLocked){
      velocity.setZero();
      return;
    }
    if (!moveDelta.isZero()) {
      //velocity += moveDelta * acceleration * dt;
      plrDir = moveDelta;
      circDir.angle = plrDir.screenAngle();
      velocity = moveDelta * maxSpeed;
      //if (velocity.length > maxSpeed) {
      //  velocity = velocity.normalized() * maxSpeed;
      //}
    } else {
      if (!velocity.isZero()) {
        double drop = friction * dt;

        if (velocity.length < drop) {
          velocity.setZero();
        } else {
          velocity -= velocity.normalized() * drop;
        }
      }
    }

    if (velocity.isZero()) return;

    position += velocity * dt;

    if (velocity.x < 0 && !visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    }
  }

  // --- NOVA FUNÇÃO DE VALIDAÇÃO DE COLISÃO ---
  bool isPhysicsCollision(PositionComponent other) {
    // Se no futuro você adicionar uma mecânica de ROLAR (Dodge/Dash) para o player
    // e criar uma variável "isAirborne", você também pode ignorar obstáculos aqui!

    if (!physicsHitbox.toAbsoluteRect().overlaps(other.toAbsoluteRect())) {
      return false;
    }
    return true;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Enemy) {
      // O Inimigo só nos causa dano se o corpo dele bater no nosso corpo!
      if (other.enemyHitbox.toAbsoluteRect().overlaps(playerHitbox.toAbsoluteRect())) {
        takeDamage(1);
      }
    }

    if (other is WallBarrier || other is Obstacle) {

      // MÁGICA AQUI: Só para de andar se bater os pés (sombra)!
      if (!isPhysicsCollision(other) || (isAirborne && other is Hole)) return;

      // Empurra pela profundidade real do overlap. O rect é lido AGORA, não no
      // começo do frame: numa quina chegam duas chamadas de onCollision no
      // mesmo frame, e a segunda precisa ver a correção que a primeira fez.
      final empurrao = empurraoParaFora(
        corpo: physicsHitbox.toAbsoluteRect(),
        alvo: other.toAbsoluteRect(),
      );
      if (empurrao.isZero()) return;

      position += empurrao;

      // Zera a velocidade só no eixo empurrado — o outro eixo continua, e é
      // isso que permite deslizar rente à parede em vez de parar de vez.
      if (empurrao.x != 0) velocity.x = 0;
      if (empurrao.y != 0) velocity.y = 0;
    }
  }

  void takeDamage(double amount) {
    if (_invulnerabilityTimer > 0) return;

    // Piso em 0, não em 1: com o piso antigo nenhum item ou habilidade de
    // redução percentual conseguia fazer diferença num golpe de 1 (o contato
    // de inimigo), porque 1 * (1 - qualquer coisa) voltava pra 1.
    //
    // `reducaoDuranteLaco` (passiva, ex.: Toco de Madeira) some junto com
    // `damageReduction` — lida direto de `capturando`, sem hook de
    // início/fim de laço nenhum.
    final reducaoLaco = capturando
        ? passivasAtivas.fold<double>(
            0.0, (acc, p) => p.reducaoDuranteLaco > acc ? p.reducaoDuranteLaco : acc)
        : 0.0;
    double amountFinal = amount * (1 - damageReduction) * (1 - reducaoLaco);
    if (amountFinal <= 0) return; // golpe totalmente mitigado: não gasta i-frame
    GameAudio.instance.play(Sfx.hit);

    _invulnerabilityTimer = _invulnerabilityDuration;
    _tempoSemApanhar = 0.0;

    // Passivas de retaliação (ex.: Retaliação Elétrica do Ouriço) — ANTES de
    // qualquer escudo, de forma que disparem sempre que o treinador tenta
    // tomar dano, mesmo que o golpe seja inteiramente absorvido pelo escudo
    // logo abaixo. Se o grupo tiver mais de uma criatura com retaliação,
    // todas executam — decisão travada com o usuário, não é "a mais forte
    // vence" (ver PIVOT_TREINADOR.md).
    for (final p in passivasAtivas) {
      p.aoTentarTomarDano(this, amountFinal);
    }

    // Regra de quebra #4 do §4.1: levar dano cancela o laço de captura — é o
    // que dá peso real à manobra (a volta é uma janela de vulnerabilidade).
    // Aqui, não antes: um golpe já mitigado por damageReduction/reducaoLaco
    // não conta como "tomar dano" pra essa regra.
    if (_capturaAlvo != null) cancelCapture();

    parent?.add(TextEffect.dano(
      amountFinal,
      position: position.clone() + Vector2(0, -size.y / 2 - 4),
      color: Palette.vermelho,
    ));

    if (shieldHits > 0) {
      shieldHits--;
      if (shieldHits <= 0) shieldVisualActive = false; // a bolha estourou
      return;
    }

    // Escudo passivo (defesa) absorve antes do HP — segunda barra, não a
    // bolha de habilidade (shieldHits), que já retornou acima se ativa.
    //
    // O excedente PASSA pro HP. Antes o escudo comia o golpe inteiro e jogava
    // o resto fora, então 1 ponto de escudo anulava um golpe de 10 do boss —
    // qualquer item de escudo ficava absurdo.
    if (shield > 0) {
      final absorvido = amountFinal > shield ? shield : amountFinal;
      shield -= absorvido;
      amountFinal -= absorvido;
      if (shield < 0) shield = 0;
      // Sem arredondar o resto pra cima: com 0.5 de escudo sobrando, um
      // arredondamento faria o golpe de 1 (contato de inimigo) chegar inteiro
      // no HP, ou seja, o último ponto fracionado de escudo sairia de graça pro
      // atacante. A barra da Hud escala contínuo, então HP fracionado desenha
      // bem.
      if (amountFinal <= 0) return;
    }

    currentHealth -= amountFinal;

    if (currentHealth <= 0) {
      onDeath?.call();
    }
  }

  @override
  void placeBomb(Vector2 dir) {
    if (bombsAmount <= 0) return;
    bombsAmount--;
    parent?.add(Bomb(position: position.clone()+(dir*17)));
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardMove.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) _keyboardMove.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) _keyboardMove.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) _keyboardMove.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) _keyboardMove.y += 1;

    final jogoAtual = game;

    // Tecla C = captura, pra testar sem depender do botão — segurar
    // inicia/mantém, soltar cancela.
    if (keysPressed.contains(LogicalKeyboardKey.keyC)) {
      startCapture();
    } else {
      cancelCapture();
    }

    // Teclas 1 e 2 = os dois slots do inventário, equivalente a clicar neles.
    // Só no KeyDownEvent: o teclado repete a tecla segurada, e com isso o
    // segundo item entraria e sairia do slot no mesmo aperto.
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) useSlot(0);
      if (event.logicalKey == LogicalKeyboardKey.digit2) useSlot(1);
      // Ação pessoal do treinador — a resposta ao playtest da fase 3.
      if (event.logicalKey == LogicalKeyboardKey.keyZ || event.logicalKey == LogicalKeyboardKey.space) dodge();
      // Recolher/liberar o grupo, pra testar sem depender do botão — troca
      // de estado, então KeyDown (uma vez por aperto), não hold como C.
      if (event.logicalKey == LogicalKeyboardKey.keyX && jogoAtual is CreaturesRogueGame) {
        jogoAtual.alternarRecuoGrupo();
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }

  bool heal(int amount) {
    if (currentHealth < maxHealth) {
      currentHealth += amount;
      if (currentHealth > maxHealth) currentHealth = maxHealth;
      return true;
    }
    return false;
  }

  void addBomb(int amount) {
    bombsAmount += amount;

    if (bombsAmount > 99) bombsAmount = 99;
  }

  void addCoins(int amount) {
    coins += amount;
  }

  /// Guarda [tipo] no primeiro slot livre. Retorna false com os dois cheios —
  /// e é esse false que faz o item continuar no chão (ver
  /// `Collectible.onCollect`), em vez de sumir sem efeito.
  bool addConsumable(ConsumableType tipo) {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) {
        slots[i] = tipo;
        return true;
      }
    }
    return false;
  }

  /// Gasta o item do slot [index]. Slot vazio é no-op, não erro: o botão da
  /// tela existe sempre, cheio ou não.
  ///
  /// O slot só é limpo se o efeito teve serventia (ver `ConsumableType.aplicar`)
  /// — poção com vida cheia, ou mapa dentro de sala trancada, não gastam o item.
  void useSlot(int index) {
    if (index < 0 || index >= slots.length) return;
    final tipo = slots[index];
    if (tipo == null) return;

    if (tipo.aplicar(this)) slots[index] = null;
  }

  /// Marca todas as salas do andar como reveladas (item Mapa). Só mexe no
  /// minimapa: `isRevealed` é separado de `isVisited` justamente pra revelar
  /// não destrancar sala nenhuma nem abrir porta (ver RoomData).
  ///
  /// Vale só pro andar atual — `nextLevel` gera RoomData novo, com o campo de
  /// volta em false, então não há o que resetar aqui.
  ///
  /// Devolve false, sem revelar nada, dentro de sala trancada: o minimapa se
  /// esconde por completo enquanto a sala não está limpa (ver
  /// `MinimapHud.render`), então usar o mapa ali gastaria o item pra não mostrar
  /// coisa nenhuma.
  bool revelarMapa() {
    final jogo = game;
    if (jogo is! CreaturesRogueGame) return false;

    final salaAtual = currentRoom?.data;
    if (salaAtual != null &&
        !salaAtual.isCleared &&
        salaAtual.type != RoomType.start) {
      return false;
    }

    for (final sala in jogo.mapData.values) {
      sala.isRevealed = true;
    }
    return true;
  }

  /// Atordoa todo inimigo da sala atual (item Congelar). Restringe à sala pelo
  /// mesmo motivo da mira automática: todos os inimigos da dungeon existem ao
  /// mesmo tempo, então sem o filtro o item congelaria o andar inteiro.
  ///
  /// Devolve false quando não havia ninguém pra congelar — assim o item não é
  /// gasto num clique fora de combate.
  bool congelarInimigos(double duracao) {
    final room = currentRoom;
    final enemies = parent?.children.whereType<Enemy>() ?? const <Enemy>[];
    bool congelouAlgum = false;

    for (final enemy in enemies) {
      if (room != null &&
          !room.toAbsoluteRect().contains(
              Offset(enemy.absolutePosition.x, enemy.absolutePosition.y))) {
        continue;
      }
      enemy.applyStun(duracao);
      congelouAlgum = true;
    }

    return congelouAlgum;
  }
}
