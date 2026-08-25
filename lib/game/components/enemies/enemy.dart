import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/condition_icons.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/effects/movement_animator.dart';
import 'package:creatures_rogue/game/components/effects/sprite_effect.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../player/player.dart';
import '../utils/palette_swapper.dart';
import '../utils/y_sort.dart';

abstract class Enemy extends PositionComponent with CollisionCallbacks, HasGameRef {
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

  final String spritePath;

  late final SpriteComponent visual;
  late final Vector2 _visualBasePosition;
  bool isAirborne;

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

  Vector2 knockbackVelocity = Vector2.zero();

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
  double lentidaoTimer = 0.0;
  double lentidaoFator = 1.0;

  /// Cegueira: enquanto > 0, o inimigo perde o rastro do jogador — quem
  /// persegue passa a andar a esmo e quem atira para de mirar. Ver
  /// ChaseMovement e ShooterAttack.
  double cegoTimer = 0.0;

  /// Velocidade sem lentidão, fotografada no construtor. Os mixins de
  /// movimento leem [speed] direto todo frame, então a lentidão escreve nele;
  /// sem uma base pra restaurar, duas aplicações sobrepostas corromperiam a
  /// velocidade permanentemente.
  late final double speedBase;

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
    this.isAirborne = false,
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

    // Hitbox: explícita > da criatura > tamanho visual.
    this.hitboxSize = hitboxSize ?? creature?.hitboxSize ?? (size ?? Vector2(16, 16));
    this.shadowOffset = shadowOffset ?? Vector2.zero();
  }

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

  void applyDot(DotKind kind, int ticks) {
    if (ticks <= 0) return;
    final atual = dots[kind];
    if (atual == null) {
      dots[kind] = Dot.criar(kind, ticks);
    } else {
      atual.reaplicar(ticks);
    }
  }

  void applyStun(double t){
    stunTimer = t;
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

  RoomComponent? _cachedRoom;

  /// A sala onde este inimigo está.
  ///
  /// Necessário porque o inimigo é filho do World, enquanto as paredes
  /// (WallBarrier) e a maioria dos obstáculos (Hole/Door) são filhos da
  /// RoomComponent — ou seja, NETOS do World. Varrer `parent!.children`
  /// nunca encontra parede nenhuma.
  RoomComponent? get currentRoom {
    final center = Offset(absolutePosition.x, absolutePosition.y);

    final cached = _cachedRoom;
    if (cached != null && cached.isMounted && cached.toAbsoluteRect().contains(center)) {
      return cached;
    }

    final p = parent;
    if (p == null) return null;

    for (final room in p.children.whereType<RoomComponent>()) {
      if (room.toAbsoluteRect().contains(center)) {
        _cachedRoom = room;
        return room;
      }
    }

    _cachedRoom = null;
    return null;
  }

  /// Todos os corpos sólidos da sala atual (paredes, pedras, buracos, portas).
  ///
  /// Pedras (Rock) são um caso à parte: viraram filhas do World (não da
  /// RoomComponent) pra entrar no Z-sort global por Y, então entram aqui
  /// filtrando as pedras do World que caem dentro do retângulo da sala.
  Iterable<PositionComponent> get roomColliders {
    final room = currentRoom;
    if (room == null) return const [];

    final localColliders = room.children
        .whereType<PositionComponent>()
        .where((c) => c is WallBarrier || c is Obstacle);

    final p = parent;
    final worldRocks = p == null
        ? const <Rock>[]
        : p.children.whereType<Rock>().where(
            (r) => room.toAbsoluteRect().overlaps(r.toAbsoluteRect()),
          );

    return localColliders.followedBy(worldRocks);
  }

  void shoot(Vector2 direction, {double? lifeTime}) {
    parent?.add(Projectile(
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

    // Guarda defensiva ativa (casco fechado) reduz o dano recebido.
    double amountFinal = amount * mult * (1 - damageReduction);
    if (amountFinal < 0) amountFinal = 0;

    parent?.add(TextEffect.dano(
      amountFinal,
      position: position.clone() + Vector2(0, -size.y / 2 - 4),
      color: corTxt,
    ));

    health -= amountFinal;
    if (health <= 0) {
      death();
    }
  }

  /// Há alguma parede ou obstáculo no caminho se andar em [dir] pelos
  /// próximos [segundos]? Vive aqui, e não no WanderMovement, porque o
  /// perambular do inimigo cego (ChaseMovement) precisa da mesma checagem —
  /// sem ela, quem fica cego encosta numa parede e raspa nela até enxergar.
  bool direcaoLivre(Vector2 dir, {double segundos = 0.6}) {
    final room = currentRoom;
    if (room == null) return true; // Segurança caso ele não esteja na tela ainda

    final double lookAheadDistance = speed * segundos;
    final Vector2 futureCenter = physicsHitbox.absoluteCenter + (dir * lookAheadDistance);

    final Rect futureRect = Rect.fromCenter(
      center: Offset(futureCenter.x, futureCenter.y),
      width: physicsHitbox.size.x,
      height: physicsHitbox.size.y,
    );

    for (final child in roomColliders) {
      if (isAirborne && child is Obstacle) continue;
      if (child.toAbsoluteRect().overlaps(futureRect)) return false;
    }

    return true;
  }

  void spawnAlerta({double duracao = 0.5}) {
    final effect = SpriteEffect(
      position: position.clone() - Vector2(0, size.y), 
      size: Vector2(16, 16), 
      corClara: Palette.indigo,
      corEscura: Palette.vermelho,
      corBranco: Palette.branco,
      spritePath: 'effects/exclamacao.png', 
      textureSize: Vector2(16, 16), 
      stepTime: duracao
    );
    parent?.add(effect);
  }

  void death() {
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


  void applyKnockback(Vector2 sourcePosition, double force) {
    Vector2 direction = (absolutePosition - sourcePosition).normalized();
    knockbackVelocity = direction * force;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) { 
    super.onCollisionStart(intersectionPoints.cast<Vector2>(), other);

    if (other is Projectile) {
      if (other.isEnemy) return; 

      takeDamage(other.dmg); 
      
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
      if (componente is Obstacle && isAirborne) continue; // voando, passa por cima
      if (destino.overlaps((componente as PositionComponent).toAbsoluteRect())) {
        return true;
      }
    }
    return false;
  }

  bool isPhysicsCollision(PositionComponent other) {
    // 1. Se está voando, passa limpo por cima de obstáculos (pedras/buracos)
    if (other is Obstacle && isAirborne) return false;
    
    // 2. Só valida a colisão se a hitbox da SOMBRA (pés) encostar no objeto.
    // Isso permite que a cabeça/corpo cruze a parede visualmente lá no alto.
    if (!physicsHitbox.toAbsoluteRect().overlaps(other.toAbsoluteRect())) {
      return false; 
    }
    
    return true;
  }
}