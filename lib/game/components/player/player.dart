import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/creatures/ability.dart';
import 'package:spacerogue/game/components/creatures/creature_data.dart';
import 'package:spacerogue/game/components/effects/movement_animator.dart';
import 'package:spacerogue/game/components/enemies/enemy.dart';
import 'package:spacerogue/game/components/map/room_component.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'package:spacerogue/game/components/projeteis/bomb.dart';
import 'package:spacerogue/game/components/utils/palette_swapper.dart';
import 'package:flutter/services.dart';
import '../map/obstacle.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameRef, KeyboardHandler{
  Vector2 _previousPosition = Vector2.zero();

  final JoystickComponent moveJoystick;
  final CreatureData creatureData;

  // Componente visual único, animado por transformação (escala/flip), não por troca de frame.
  late final SpriteComponent visual;
  late final Vector2 _visualBasePosition;
  late final MovementAnimator _moveAnimator;

  // Bolha desenhada por cima do player enquanto uma habilidade defensiva
  // (Bolha Protetora, Casco Fechado) está com o efeito ativo.
  late final SpriteComponent shieldVisual;
  bool shieldVisualActive = false;

  // --- NOVAS VARIÁVEIS DE COLISÃO ---
  late RectangleHitbox playerHitbox;  // Colisor de Combate (Corpo)
  late RectangleHitbox physicsHitbox; // Colisor de Física (Pés/Sombra)

  final Vector2 _keyboardMove = Vector2.zero();

  int maxHealth;
  int currentHealth;

  double _invulnerabilityTimer = 0.0;
  final double _invulnerabilityDuration = 1.5;

  int bombsAmount = 3;

  Vector2 velocity = Vector2.zero();
  Vector2 knockbackVelocity = Vector2.zero();
  Vector2 plrDir = Vector2(0,1);

  double get maxSpeed => creatureData.stats.speed;
  final double acceleration = 100.0;
  final double friction = 200.0;

  /// Direção que as habilidades (e a bomba) disparam: sempre o inimigo mais
  /// próximo dentro da sala atual. Sem inimigo à vista, mantém a última mira.
  Vector2 lockedAb1Direction = Vector2(0,1);
  Vector2 lockedAb2Direction = Vector2(0,1);

  bool naoMove = false;

  // --- Ganchos usados pelas habilidades das criaturas (Ability) ---
  // Neutros por padrão: nada muda enquanto nenhuma habilidade os usa.
  double damageReduction = 0.0;
  bool speedLocked = false;
  int shieldHits = 0;

  double _cooldown1 = 0.0;
  double _cooldown2 = 0.0;

  // Segurando o botão (touch ou teclado), a habilidade dispara sozinha assim
  // que o cooldown zerar — não precisa soltar e apertar de novo.
  bool _keyboardHoldAbility1 = false;
  bool _keyboardHoldAbility2 = false;
  bool touchHoldAbility1 = false;
  bool touchHoldAbility2 = false;

  void grantInvulnerability(double seconds) {
    if (seconds > _invulnerabilityTimer) _invulnerabilityTimer = seconds;
  }

  Player({
    required this.moveJoystick,
    required this.creatureData,
  }) : maxHealth = creatureData.stats.maxHp,
       currentHealth = creatureData.stats.maxHp,
       super(size: Vector2(16, 16), anchor: Anchor.center, priority: 10);

  VoidCallback? onDeath;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    //debugMode = true;

    final ui.Image spriteImage = await PaletteSwapper.createSwappedImage(
      imagePath: creatureData.spritePath,
      lightGrayReplacement: creatureData.corClara,
      darkGrayReplacement: creatureData.corEscura,
    );

    _visualBasePosition = Vector2(size.x / 2, size.y);
    _moveAnimator = MovementAnimator(creatureData.moveAnim);

    visual = SpriteComponent(
      sprite: Sprite(spriteImage),
      size: size,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition.clone(),
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 1,
    );
    add(visual);

    final ui.Image shieldImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'projeteis/bolha.png',
      lightGrayReplacement: Palette.azul,
      darkGrayReplacement: Palette.azulEsc,
      whiteReplacement: Palette.branco,
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

    // --- 1. COLISOR DE COMBATE (Corpo Inteiro) — tamanho vem da criatura ---
    final hitboxSize = creatureData.hitboxSize;
    playerHitbox = RectangleHitbox(
      size: hitboxSize,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition,
      collisionType: CollisionType.active,
    );
    //playerHitbox.debugMode = true;
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
      position: size / 2 + Vector2(0, hitboxSize.y / 2),
      paint: shadowPaint,
      priority: -1,
    )..scale = Vector2(1.2, 0.75);

    add(shadow);
  }

  @override
  void update(double dt) {
    _previousPosition = position.clone();
    super.update(dt);

    if (_cooldown1 > 0) _cooldown1 -= dt;
    if (_cooldown2 > 0) _cooldown2 -= dt;

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

    if(creatureData.ability1.target == AbilityTarget.enemyDir ){
      lockedAb1Direction = _findNearestEnemyDirection(lockedAb1Direction);
    }else if(creatureData.ability1.target == AbilityTarget.plrDir ){
      lockedAb1Direction = plrDir.normalized();
    }else if(creatureData.ability1.target == AbilityTarget.joyDir ){
      lockedAb1Direction = velocity.normalized();
    }

    if(creatureData.ability2.target == AbilityTarget.enemyDir ){
      lockedAb2Direction = _findNearestEnemyDirection(lockedAb2Direction);
    }else if(creatureData.ability2.target == AbilityTarget.plrDir ){
      lockedAb2Direction = plrDir.normalized();
    }else if(creatureData.ability2.target == AbilityTarget.joyDir ){
      lockedAb2Direction = velocity.normalized();
    }

    if (_keyboardHoldAbility1 || touchHoldAbility1) useAbility1();
    if (_keyboardHoldAbility2 || touchHoldAbility2) useAbility2();

    _updateMovement(dt, moveDelta);

    _moveAnimator.update(
      visual: visual,
      basePosition: _visualBasePosition,
      isMoving: !velocity.isZero(),
      horizontalDir: velocity.isZero() ? 0.0 : velocity.normalized().x,
      dt: dt,
    );
  }

  /// Sala onde o player está agora (mesma lógica usada por `Enemy.currentRoom`).
  RoomComponent? get _currentRoom {
    final p = parent;
    if (p == null) return null;
    final center = Offset(absolutePosition.x, absolutePosition.y);
    for (final room in p.children.whereType<RoomComponent>()) {
      if (room.toAbsoluteRect().contains(center)) return room;
    }
    return null;
  }

  /// Direção até o inimigo vivo mais próximo, restrito à sala atual (senão o
  /// player miraria através de paredes em inimigos de outras salas, já que
  /// todos os inimigos da dungeon existem simultaneamente). Sem inimigo na
  /// sala, mantém a última direção conhecida.
  Vector2 _findNearestEnemyDirection(Vector2 dir) {
    final room = _currentRoom;
    final enemies = parent?.children.whereType<Enemy>() ?? const <Enemy>[];

    Enemy? nearest;
    double nearestDistSq = double.infinity;

    for (final enemy in enemies) {
      if (room != null &&
          !room.toAbsoluteRect().contains(
              Offset(enemy.absolutePosition.x, enemy.absolutePosition.y))) {
        continue;
      }
      final distSq = (enemy.absolutePosition - absolutePosition).length2;
      if (distSq < nearestDistSq) {
        nearestDistSq = distSq;
        nearest = enemy;
      }
    }

    if (nearest == null) return dir;
    final delta = nearest.absolutePosition - absolutePosition;
    if (delta.length == 0) return dir;
    return delta.normalized();
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
      velocity += moveDelta * acceleration * dt;
      plrDir = moveDelta;
      if (velocity.length > maxSpeed) {
        velocity = velocity.normalized() * maxSpeed;
      }
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

  void useAbility1() {
    if (_cooldown1 > 0) return;
    creatureData.ability1.execute(this, lockedAb1Direction);
    _cooldown1 = creatureData.ability1.cooldown;
  }

  void useAbility2() {
    if (_cooldown2 > 0) return;
    creatureData.ability2.execute(this, lockedAb2Direction);
    _cooldown2 = creatureData.ability2.cooldown;
  }

  /// Fração restante de cooldown de cada botão (0 = pronto, 1 = acabou de usar).
  /// Usado pela HUD para desenhar os indicadores (fase 6).
  double get ability1CooldownFraction =>
      (_cooldown1 / creatureData.ability1.cooldown).clamp(0.0, 1.0);
  double get ability2CooldownFraction =>
      (_cooldown2 / creatureData.ability2.cooldown).clamp(0.0, 1.0);

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
      if (!isPhysicsCollision(other)) return;

      Vector2 collisionCenter = Vector2.zero();
      for (var point in intersectionPoints) {
        collisionCenter += point;
      }
      collisionCenter /= intersectionPoints.length.toDouble();

      // USA O CENTRO DA SOMBRA E NÃO O CENTRO DO CORPO PARA EVITAR GRUDAR NA PAREDE SUPERIOR
      Vector2 diff = physicsHitbox.absoluteCenter - collisionCenter;

      if (diff.x.abs() > diff.y.abs()) {
        position.x = _previousPosition.x;
        velocity.x = 0;
      } else {
        position.y = _previousPosition.y;
        velocity.y = 0;
      }
    }
  }

  void takeDamage(int amount) {
    if (_invulnerabilityTimer > 0) return;

    if (shieldHits > 0) {
      shieldHits--;
      if (shieldHits <= 0) shieldVisualActive = false; // a bolha estourou
      return;
    }

    int amountFinal = (amount * (1 - damageReduction)).ceil();
    if (amountFinal < 1) amountFinal = 1;

    currentHealth -= amountFinal;
    _invulnerabilityTimer = _invulnerabilityDuration;

    if (currentHealth <= 0) {
      onDeath?.call();
    }
  }

  void _placeBomb() {
    if (bombsAmount > 0) {
      bombsAmount--;
      parent?.add(Bomb(position: position.clone()+(lockedAb1Direction.clone()*17)));
    } else {
      print("Sem bombas!");
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardMove.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) _keyboardMove.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) _keyboardMove.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) _keyboardMove.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) _keyboardMove.y += 1;

    _keyboardHoldAbility1 = keysPressed.contains(LogicalKeyboardKey.keyZ);
    _keyboardHoldAbility2 = keysPressed.contains(LogicalKeyboardKey.keyX);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) _placeBomb();
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
}
