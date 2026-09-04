import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/creatures/movement_host.dart';
import 'package:creatures_rogue/game/components/effects/condition_icons.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/effects/movement_animator.dart';
import 'package:creatures_rogue/game/components/effects/sprite_effect.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/map/door.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import 'package:creatures_rogue/l10n/creature_i18n.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import '../player/player.dart';
import '../utils/palette_swapper.dart';
import '../utils/y_sort.dart';

abstract class Enemy extends PositionComponent with CollisionCallbacks, HasGameRef, MovementHost {
  final Player playerTarget;
  
  double speed;
  double health;

  /// Vida com que este inimigo nasceu. Só serve pra calcular fração de vida
  /// (barra de boss) — nada no jogo cura inimigo, então nunca muda.
  late final double maxHealth;

  int dmg;
  double bltSpeed;
  String bltImg;
  Color bltCor1;
  Color bltCor2;

  Color corClara;
  Color corEscura;
  Color corBranco;
  late Vector2 hitboxSize;
  late Vector2 shadowOffset;
  late RectangleHitbox enemyHitbox;
  late RectangleHitbox physicsHitbox;

  /// A criatura que este inimigo é. Quando passada, fornece sprite, cores,
  /// hitbox e estilo de animação — a subclasse só precisa codificar
  /// COMPORTAMENTO. Stats (speed/health/dmg) continuam tunados à mão por
  /// classe, usando `creature.stats` apenas como referência de projeto.
  final CreatureData? creature;

  /// Satisfaz o contrato de `ShooterAttack` (ver `enemy_mixins.dart`) pra
  /// quem usa esse mixin — não precisa reimplementar por inimigo, já que o
  /// som é sempre o do tipo elemental da própria criatura.
  Sfx? get attackSfx => creature?.tipo.attackSfx;

  final String spritePath;

  late final SpriteComponent visual;
  late final Vector2 _visualBasePosition;
  // `isAirborne` vem de MovementHost; valor inicial é atribuído no corpo do
  // construtor (ver abaixo), já que `this.isAirborne` shorthand só funciona
  // pra campo declarado na própria classe.

  late final SpriteComponent shieldVisual;
  bool shieldVisualActive = false;

  late final ConditionIcons conditionIcons;
  /// Estilo de animação de movimento (ver MovementAnimator). Null = inimigo
  /// sem animação genérica de movimento — ou porque o próprio mecanismo de
  /// movimento já é a animação (ex.: JumpMovement, que pula de verdade), ou
  /// porque ele nunca se move (ex.: boneco de treino).
  final MovementAnimation? moveAnim;
  MovementAnimator? _moveAnimator;

  /// Se false, o inimigo não é empurrado por outros inimigos (planta, torreta...)
  bool isPushable;

  // `knockbackVelocity` vem de MovementHost.

  /// Gancho usado por habilidades de controle de grupo (ex.: Corrente
  /// Estática). Enquanto > 0, o inimigo não chama `movimento`.
  double stunTimer = 0.0;

  /// Gancho de guarda defensiva (ex.: casco fechado da tartaruga). Neutro por
  /// padrão: 0.0 não muda nada. Lido em `takeDamage`.
  double damageReduction = 0.0;

  /// Danos ao longo do tempo ativos, no máximo um por variante — reaplicar
  /// veneno em cima de veneno acumula ticks no mesmo Dot em vez de criar um
  /// segundo. Ver [Dot].
  final Map<DotKind, Dot> dots = {};

  /// Lentidão: enquanto > 0, a velocidade efetiva é [speed] * [lentidaoFator].
  /// Reaplicar renova a duração e mantém o fator mais forte — nunca multiplica
  /// um sobre o outro, senão duas aplicações travam o inimigo de vez.
  /// `lentidaoFator` vem de MovementHost.
  double lentidaoTimer = 0.0;

  // `cegoTimer` vem de MovementHost. Cegueira: enquanto > 0, o inimigo perde
  // o rastro do jogador — quem persegue passa a andar a esmo e quem atira
  // para de mirar. Ver ChaseMovement e ShooterAttack.

  /// Velocidade sem lentidão, fotografada no construtor. Os mixins de
  /// movimento leem [speed] direto todo frame, então a lentidão escreve nele;
  /// sem uma base pra restaurar, duas aplicações sobrepostas corromperiam a
  /// velocidade permanentemente.
  late final double speedBase;

  /// Relógio do pisca-pisca de vida baixa (< 30% de maxHealth). Só avança
  /// enquanto a condição vale; ver `update`.
  double _lowHpBlinkClock = 0.0;

  Enemy({
    required Vector2 position,
    required this.playerTarget,
    this.creature,
    String? spritePath,
    Color? corClara,
    Color? corEscura,
    MovementAnimation? moveAnim,
    this.speed = 30.0,
    this.health = 1,
    this.dmg = 1,
    this.bltSpeed = 75,
    bool isAirborne = false,
    this.bltCor1 = Palette.vermelho,
    this.bltCor2 = Palette.laranja,
    this.bltImg = 'projeteis/tiro2.png',
    this.isPushable = true,
    this.corBranco = Palette.branco,
    Vector2? size,
    Vector2? hitboxSize,
    Vector2? shadowOffset,
  }) : spritePath = spritePath ?? creature?.spritePath ?? 'actors/dummy.png',
       corClara = corClara ?? creature?.corClara ?? Palette.cinza,
       corEscura = corEscura ?? creature?.corEscura ?? Palette.cinzaEsc,
       moveAnim = moveAnim ?? creature?.moveAnim,
       super(
         position: position,
         size: size ?? Vector2(16, 16), // Tamanho VISUAL padrão
         anchor: Anchor.center,
       ) {
    maxHealth = health;
    speedBase = speed;
    this.isAirborne = isAirborne;

    // Hitbox: explícita > da criatura > tamanho visual.
    this.hitboxSize = hitboxSize ?? creature?.hitboxSize ?? (size ?? Vector2(16, 16));
    this.shadowOffset = shadowOffset ?? Vector2.zero();
  }

  /// O jogador — alvo fixo de todo `Enemy` (ver PIVOT_TREINADOR.md §3.4).
  @override
  PositionComponent get currentTarget => playerTarget;

  @override
  Future onLoad() async {
    final ui.Image enemyImage = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
      whiteReplacement: corBranco,
    );

    _visualBasePosition = Vector2(size.x / 2, size.y);
    final anim = moveAnim;
    if (anim != null) _moveAnimator = MovementAnimator(anim);

    visual = SpriteComponent(
      sprite: Sprite(enemyImage),
      size: size,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition.clone(),
      paint: Paint()..filterQuality = FilterQuality.none,
    );
    add(visual);

    final ui.Image shieldImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'projeteis/bolha.png',
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
      whiteReplacement: corBranco,
    );
    shieldVisual = SpriteComponent(
      sprite: Sprite(shieldImage),
      size: Vector2.all(24),
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 5,
    );
    shieldVisual.setOpacity(0.0); // só aparece enquanto shieldVisualActive
    add(shieldVisual);

    conditionIcons = ConditionIcons()..position = Vector2(size.x / 2, -2);
    add(conditionIcons);

    enemyHitbox = RectangleHitbox(
      size: hitboxSize,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition, 
      collisionType: CollisionType.active,
    );
    add(enemyHitbox);

    physicsHitbox = RectangleHitbox(
      size: Vector2(hitboxSize.x, hitboxSize.x * 0.5),
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, hitboxSize.y / 2) + shadowOffset,
      collisionType: CollisionType.active,
    );
    add(physicsHitbox);

    final shadowPaint = Paint()..color = Palette.preto; // Preto com 40% de opacidade
    
    final shadow = CircleComponent(
      radius: hitboxSize.x / 2, // O raio é metade da largura da Hitbox
      anchor: Anchor.center,
      position: _visualBasePosition + shadowOffset,
      paint: shadowPaint,
      priority: -1, 
    )..scale = Vector2(1.0, 0.75);
    
    add(shadow);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Anchor.center: o "chão" (pés) fica meio size.y abaixo do centro.
    priority = ySortPriority(position.y + size.y / 2);

    // Pisca vermelho com vida abaixo de 30%. Roda independente de stun/raiz/
    // knockback — é indicador de vida, não movimento — mas só enquanto o
    // inimigo está vivo, senão `death()` já matou o componente.
    if (health > 0 && (health / maxHealth) < 0.3) {
      _lowHpBlinkClock += dt;
      visual.paint.colorFilter = (_lowHpBlinkClock % 0.4) < 0.2
          ? const ColorFilter.mode(Palette.vermelho, BlendMode.srcATop)
          : null;
    } else if (_lowHpBlinkClock != 0.0) {
      _lowHpBlinkClock = 0.0;
      visual.paint.colorFilter = null;
    }
    shieldVisual.setOpacity(shieldVisualActive ? 1.0 : 0.0);

    // Condições correm ANTES dos returns de knockback e stun. Se ficassem no
    // fim, um atordoamento de 1.5s comeria uma queimadura inteira (0.7s) sem
    // ela tickar uma vez — o veneno antigo escondia isso por durar 3s.
    updateCondicoes(dt);
    // Um tick de DoT pode ter matado o inimigo. `removeFromParent` só tira o
    // componente no fim do frame, então `isMounted` ainda estaria true aqui —
    // a vida é o teste confiável.
    if (health <= 0) return;
    conditionIcons.stunAtivo = stunTimer > 0;
    conditionIcons.venenoAtivo = dots.containsKey(DotKind.veneno);
    conditionIcons.queimaduraAtivo = dots.containsKey(DotKind.queimadura);
    conditionIcons.lentidaoAtivo = lentidaoTimer > 0;
    conditionIcons.cegoAtivo = cegoTimer > 0;


    if (!knockbackVelocity.isZero()) {
      position += knockbackVelocity * dt;
      
      double drop = 120.0 * dt; // Atrito
      if (knockbackVelocity.length < drop) {
        knockbackVelocity.setZero();
      } else {
        knockbackVelocity -= knockbackVelocity.normalized() * drop;
      }
      return; // Pula o método de movimento, o inimigo não "pensa" enquanto voa pra trás
    }

    if (stunTimer > 0) {
      stunTimer -= dt;
      return;
    }
    movimento(dt);
  }

  static final Paint _hpBarraMoldura = Paint()..color = Palette.preto;
  static final Paint _hpBarraFundo = Paint()..color = Palette.cinzaEsc;
  static const double _hpBarraLargura = 14.0;
  static const double _hpBarraAltura = 2.0;

  void _renderBarraEsquiva(Canvas canvas) {
    final porcentagem = (health/maxHealth);
    final left = (size.x - _hpBarraLargura) / 2;
    final top = - 4.0;

    Paint hpBarraPreenchimento = Paint()..color = (health/maxHealth) < 0.3? Palette.vermelho : Palette.verde;

    canvas.drawRect(
      Rect.fromLTWH(left - 1, top - 1, _hpBarraLargura + 2, _hpBarraAltura + 2),
      _hpBarraMoldura,
    );
    canvas.drawRect(Rect.fromLTWH(left, top, _hpBarraLargura, _hpBarraAltura), _hpBarraFundo);
    canvas.drawRect(
        Rect.fromLTWH(left, top, _hpBarraLargura * porcentagem, _hpBarraAltura),
        hpBarraPreenchimento,
      );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderBarraEsquiva(canvas);
  }

  void applyDot(DotKind kind, int ticks) {
    if (ticks <= 0) return;
    final atual = dots[kind];
    if (atual == null) {
      dots[kind] = Dot.criar(kind, ticks);
    } else {
      atual.reaplicar(ticks);
    }
  }

  /// Reaplicar renova a duração e fica com a maior — nunca sobrescreve seco,
  /// mesma regra de [applyLentidao] logo abaixo. Sem isso, duas retaliações
  /// de passiva atordoando no mesmo frame (ver PIVOT_TREINADOR.md) deixavam
  /// a duração final depender só da ordem de processamento da lista.
  void applyStun(double t){
    stunTimer = t > stunTimer ? t : stunTimer;
  }

  /// [fator] é a fração da velocidade original (0.5 = metade). Reaplicar
  /// renova a duração e fica com o fator mais forte, nunca multiplica um
  /// sobre o outro.
  void applyLentidao(double duracao, {double fator = 0.5}) {
    lentidaoTimer = duracao > lentidaoTimer ? duracao : lentidaoTimer;
    lentidaoFator = fator < lentidaoFator ? fator : lentidaoFator;
    speed = speedBase * lentidaoFator;
  }

  void applyCego(double duracao) {
    if (duracao > cegoTimer) cegoTimer = duracao;
  }

  void updateCondicoes(double dt) {
    // Cópia da lista: um tick pode remover o Dot ou matar o inimigo.
    for (final dot in dots.values.toList()) {
      dot.timer -= dt;
      if (dot.timer > 0) continue;

      dot.ticks--;
      dot.timer = dot.intervalo;
      if (dot.ticks <= 0) dots.remove(dot.kind);

      takeDamage(dot.dano, corTxt: dot.cor, tipoAtacante: dot.tipo);
      if (health <= 0) return;
    }

    if (lentidaoTimer > 0) {
      lentidaoTimer -= dt;
      if (lentidaoTimer <= 0) {
        lentidaoFator = 1.0;
        speed = speedBase;
      }
    }

    if (cegoTimer > 0) cegoTimer -= dt;
  }

  void movimento(double dt);

  /// Toca a animação de movimento genérica (se a criatura tiver uma —
  /// ver [moveAnim]). Mixins de movimento contínuo (WanderMovement,
  /// ChaseMovement) chamam isso a cada frame com o estado atual.
  void animateMovement(double dt, {required bool isMoving, double horizontalDir = 0.0}) {
    _moveAnimator?.update(
      visual: visual,
      basePosition: _visualBasePosition,
      isMoving: isMoving,
      horizontalDir: horizontalDir,
      dt: dt,
    );
  }

  // `currentRoom` e `roomColliders` vêm de MovementHost.

  void shoot(Vector2 direction, {double? lifeTime}) {
    parent?.add(Projectile(
      owner: this,
      position: position.clone() + direction*size.x/2,
      direction: direction,
      isEnemy: true,
      speed: bltSpeed,
      dmg: dmg.toDouble(),
      sprPath: bltImg,
      cor1: bltCor1,
      cor2: bltCor2,
      lifeTime: lifeTime,
      // Só importa se o tiro for refletido (casco fechado) e virar tiro do
      // jogador: o Player não sofre multiplicador de tipo.
      tipo: creature?.tipo ?? CreatureType.neutro,
    ));
  }

  /// [tipoAtacante] aplica a vantagem elemental (ver `typeMultiplier`).
  /// `neutro` — o padrão — vale 1.0, então quem não passa tipo não muda nada.
  void takeDamage(double amount,{Color corTxt = Palette.amarelo, CreatureType tipoAtacante = CreatureType.neutro}) {
    final mult = typeMultiplier(tipoAtacante, creature?.tipo ?? CreatureType.neutro);
    double fontSize = 6;

    if (mult > 1.0) {
      fontSize = 12;
    } else if(mult < 1.0) {
      //fontSize = 4;
      corTxt = Palette.cinza;
    }
    // Guarda defensiva ativa (casco fechado) reduz o dano recebido.
    double amountFinal = amount * mult * (1 - damageReduction);
    if (amountFinal < 0) amountFinal = 0;
   // if (amountFinal > 0)
    GameAudio.instance.play(Sfx.hit);

    var critChance = Random().nextDouble() * 100;
    if(playerTarget.critChance >=  critChance ) {
      amountFinal *= playerTarget.critMult;
      corTxt = Palette.vermelho;
      print('crit $critChance');
    }
    
    parent?.add(TextEffect.dano(
      amountFinal,
      position: position.clone() + Vector2(0, -size.y / 2 - 4),
      color: corTxt,
      fontSize: fontSize,
    ));

    health -= amountFinal;
    if (health <= 0) {
      death();
    }
  }

  // `direcaoLivre` e `spawnAlerta` vêm de MovementHost.

  void death() {
    GameAudio.instance.play(Sfx.enemy_die);
    // Sem await de propósito: death() não é async (chamado de dentro de
    // takeDamage, síncrono), e a contagem não precisa bloquear a morte —
    // só precisa acabar gravada eventualmente.
    final id = creature?.id;
    if (id != null) CreatureProgress.instance.incrementKill(id);

    final effect = SpriteEffect(
      position: position.clone(), 
      size: Vector2(16, 16), 
      corClara: Palette.indigo,
      corEscura: Palette.cinzaEsc,
      corBranco: Palette.branco,
      spritePath: 'effects/enemy_death.png', 
      textureSize: Vector2(16, 16), 
    );
    parent?.add(effect);
    removeFromParent();
  }

  /// Libera `creature` pra jogar e avisa na tela — cada boss chama isto no
  /// próprio `death()`, antes do `super.death()`. Centralizado aqui (em vez
  /// de repetir o texto em cada boss) porque todos já têm `creature`, `parent`
  /// e `position` prontos pelo mesmo motivo do dano em `takeDamage`.
  void unlockCreature() {
    final data = creature;
    if (data == null) return;

    CreatureProgress.instance.unlock(data.id);
    final context = game.buildContext!;
    parent?.add(TextEffect(
      text: context.l10n.effect_criaturaLiberada(creatureName(context, data.id)),
      position: position.clone() + Vector2(0, -size.y / 2 - 4),
      color: Palette.branco,
    ));
  }

  void applyKnockback(Vector2 sourcePosition, double force) {
    Vector2 direction = (absolutePosition - sourcePosition).normalized();
    knockbackVelocity = direction * force;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints.cast<Vector2>(), other);
    if (other is Projectile) {
      if (other.isEnemy) return;

      // Só o flash visual aqui. O dano já é aplicado do lado do projétil
      // (`Projectile.onCollisionStart`, ramo `other is Enemy`), que sabe o
      // tipo elemental, `Player.danoMult`, knockback e perfuração — chamar
      // `takeDamage` de novo aqui duplicava o golpe: uma vez com tipo (o do
      // projétil) e outra sem (esta, com `other.dmg` cru).
      visual.paint.colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isRemoved) {
          visual.paint.colorFilter = null;
        }
      });
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // --- Lógica de Flocking (esbarrão entre inimigos) ---
    if (other is Enemy) {
      // Inimigos fixos (planta) não saem do lugar; o OUTRO inimigo se desvia
      if (!isPushable) return;

      Vector2 separationVector = absolutePosition - other.absolutePosition;
      final desvio = separationVector.length > 0
          ? separationVector.normalized() * 0.5
          : Vector2(0.5, 0);

      // Só desvia se o destino estiver livre. Sem esta checagem o esbarrão
      // enfia o inimigo dentro da parede — e como boss tem isPushable false,
      // ele vira um pistão empurrando os comuns pra dentro do cenário.
      if (!_paredeNoCaminho(desvio)) position += desvio;
      return;
    }

    // --- Lógica de Paredes e Obstáculos ---
    if (other is WallBarrier || other is Obstacle) {
      
      // AQUI ESTÁ A MÁGICA: Se a colisão não foi nos pés (sombra), ignora a parede!
      if (!isPhysicsCollision(other)) return;

      // Empurra pela profundidade real do overlap. O rect é lido AGORA, não no
      // começo do frame: numa quina chegam duas chamadas de onCollision no
      // mesmo frame, e a segunda precisa ver a correção que a primeira fez.
      final empurrao = empurraoParaFora(
        corpo: physicsHitbox.toAbsoluteRect(),
        alvo: other.toAbsoluteRect(),
      );
      if (empurrao.isZero()) return;

      position += empurrao;

      // Corta o knockback só no eixo empurrado. Zerar tudo (como antes) mata
      // também o empurrão tangencial, que é o que deslizaria pela parede.
      if (empurrao.x != 0) knockbackVelocity.x = 0;
      if (empurrao.y != 0) knockbackVelocity.y = 0;
    }
  }

  /// Se mover a sombra por [desvio] encostaria em parede ou obstáculo sólido.
  /// Usado pelo esbarrão entre inimigos, que escreve position direto e por isso
  /// não passa pela resolução de parede.
  bool _paredeNoCaminho(Vector2 desvio) {
    final destino = physicsHitbox.toAbsoluteRect().shift(Offset(desvio.x, desvio.y));

    for (final componente in parent?.children ?? const Iterable.empty()) {
      if (componente is! WallBarrier && componente is! Obstacle) continue;
      // Voando passa por cima de pedra/buraco, mas NUNCA de porta: `Door`
      // também é `Obstacle`, e sem esta exceção o inimigo voador saía da sala
      // trancada — e, como ele continua em `activeEnemies`, a sala nunca
      // destrancava.
      if (componente is Obstacle && componente is! Door && isAirborne) continue;
      if (destino.overlaps((componente as PositionComponent).toAbsoluteRect())) {
        return true;
      }
    }
    return false;
  }

  bool isPhysicsCollision(PositionComponent other) {
    // 1. Se está voando, passa limpo por cima de obstáculos (pedras/buracos).
    //    Porta fica de fora: `Door` estende `Obstacle`, e deixá-la aqui fazia o
    //    inimigo voador atravessar porta trancada.
    if (other is Obstacle && other is! Door && isAirborne) return false;
    
    // 2. Só valida a colisão se a hitbox da SOMBRA (pés) encostar no objeto.
    // Isso permite que a cabeça/corpo cruze a parede visualmente lá no alto.
    if (!physicsHitbox.toAbsoluteRect().overlaps(other.toAbsoluteRect())) {
      return false; 
    }
    
    return true;
  }
}