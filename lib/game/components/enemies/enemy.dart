import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/effects/movement_animator.dart';
import 'package:creatures_rogue/game/components/effects/sprite_effect.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../player/player.dart';
import '../utils/palette_swapper.dart'; 

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

  late Vector2 _previousPosition;
  late final SpriteComponent visual;
  late final Vector2 _visualBasePosition;
  bool isAirborne;

  late final SpriteComponent shieldVisual;
  bool shieldVisualActive = false;
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

  int poisonCount = 0;
  double poisonTimer = 0.0;
  double poisonDur = 1.0;

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
    _previousPosition = position.clone();
    maxHealth = health;

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

    _visualBasePosition = size / 2;
    final anim = moveAnim;
    if (anim != null) _moveAnimator = MovementAnimator(anim);

    visual = SpriteComponent(
      sprite: Sprite(enemyImage),
      size: size,
      anchor: Anchor.center,
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

    enemyHitbox = RectangleHitbox(
      size: hitboxSize,
      anchor: Anchor.center,
      position: size / 2, 
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
      position: size / 2 + Vector2(0, hitboxSize.y / 2) + shadowOffset,
      paint: shadowPaint,
      priority: -1, 
    )..scale = Vector2(1.0, 0.75);
    
    add(shadow);
  }

  @override
  void update(double dt) {
    _previousPosition = position.clone();
    super.update(dt);

    shieldVisual.setOpacity(shieldVisualActive ? 1.0 : 0.0);

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
      return; // Atordoado: também não "pensa"
    }

    movimento(dt);
    updateCondicoes(dt);
  }

  void applyPoison(int count){
    poisonCount = count;
    poisonTimer = poisonDur;
  }

  void updateCondicoes(double dt) {
    if (poisonCount > 0){
      poisonTimer -= dt;
      if (poisonTimer <= 0){
        poisonCount--;
        poisonTimer = poisonDur;
        takeDamage(2, corTxt: Palette.verde);
      }
    }
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
  /// (WallBarrier) e os obstáculos (Rock/Hole/Door) são filhos da
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
  Iterable<PositionComponent> get roomColliders {
    final room = currentRoom;
    if (room == null) return const [];
    return room.children
        .whereType<PositionComponent>()
        .where((c) => c is WallBarrier || c is Obstacle);
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
    ));
  }

  void takeDamage(double amount,{Color corTxt = Palette.amarelo}) {
    // Guarda defensiva ativa (casco fechado) reduz o dano recebido.
    double amountFinal = amount * (1 - damageReduction);
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
      if (separationVector.length > 0) {
        position += separationVector.normalized() * 0.5; 
      } else {
        position.x += 0.5; 
      }
      return;
    }

    // --- Lógica de Paredes e Obstáculos ---
    if (other is WallBarrier || other is Obstacle) {
      
      // AQUI ESTÁ A MÁGICA: Se a colisão não foi nos pés (sombra), ignora a parede!
      if (!isPhysicsCollision(other)) return; 

      knockbackVelocity.setZero();
      
      Vector2 collisionCenter = Vector2.zero();
      for (var point in intersectionPoints) {
        collisionCenter += point;
      }
      collisionCenter /= intersectionPoints.length.toDouble();

      Vector2 diff = physicsHitbox.absoluteCenter - collisionCenter;
      
      if (diff.x.abs() > diff.y.abs()) {
        position.x = _previousPosition.x;
      } else {
        position.y = _previousPosition.y;
      }
    }
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