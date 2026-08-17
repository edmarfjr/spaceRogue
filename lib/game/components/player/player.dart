import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'package:spacerogue/game/components/projeteis/bomb.dart';
import 'package:spacerogue/game/components/utils/palette_swapper.dart';
import '../projeteis/projectile.dart';
import 'package:flutter/services.dart';
import '../map/obstacle.dart';

enum AimDirection { down, right, up, left }

class Player extends PositionComponent with CollisionCallbacks, HasGameRef, KeyboardHandler{
  Vector2 _previousPosition = Vector2.zero();

  final JoystickComponent moveJoystick;
  final JoystickComponent aimJoystick;

  // Componentes visuais
  late final SpriteAnimationComponent body;
  late final SpriteComponent head;
  late final SpriteComponent weapon;

  late final SpriteAnimation bodyVerticalAnim;
  late final SpriteAnimation bodyHorizontalAnim;

  late final List<Sprite> headSprites;
  late final List<Sprite> weaponSprites;

  // --- NOVAS VARIÁVEIS DE COLISÃO ---
  late RectangleHitbox playerHitbox;  // Colisor de Combate (Corpo)
  late RectangleHitbox physicsHitbox; // Colisor de Física (Pés/Sombra)

  double speed = 60.0;

  int currentAimIndex = 0;

  double fireRate = 0.35; 
  double _shootTimer = 0.0;     
  double dmg = 1;
  double kbForce = 20;

  Color corClara;
  Color corEscura;

  final Vector2 _keyboardMove = Vector2.zero();
  final Vector2 _keyboardAim = Vector2.zero();

  int maxHealth = 4;
  int currentHealth = 4;

  double _invulnerabilityTimer = 0.0;
  final double _invulnerabilityDuration = 1.5;

  int bombsAmount = 3;

  Vector2 velocity = Vector2.zero(); 

  final double maxSpeed = 50.0;        
  final double acceleration = 100.0;  
  final double friction = 200.0;

  Vector2 lockedFireDirection = Vector2(0,1);

  bool naoMove = false;

  Player({
    required this.moveJoystick, 
    required this.aimJoystick,  
    this.corClara = Palette.vermelho, 
    this.corEscura = Palette.azul, 
  }) : super(size: Vector2(16, 16), anchor: Anchor.center, priority: 10);

  VoidCallback? onDeath;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final ui.Image corpoImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'actors/corpo.png',
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
    );
    bodyVerticalAnim = SpriteAnimation.fromFrameData(
      corpoImage,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(16, 16)),
    );
    
    final ui.Image corpoLadoImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'actors/corpoLado.png',
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
    );
    bodyHorizontalAnim = SpriteAnimation.fromFrameData(
      corpoLadoImage,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(16, 16)),
    );

    body = SpriteAnimationComponent(
      animation: bodyVerticalAnim,
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 1,
    );

    final ui.Image headImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'actors/cabeca.png',
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
    );

    headSprites = [
      Sprite(headImage, srcSize: Vector2(16, 16), srcPosition: Vector2(0, 0)),
      Sprite(headImage, srcSize: Vector2(16, 16), srcPosition: Vector2(16, 0)),
      Sprite(headImage, srcSize: Vector2(16, 16), srcPosition: Vector2(32, 0)),
      Sprite(headImage, srcSize: Vector2(16, 16), srcPosition: Vector2(48, 0)),
    ];

    final ui.Image weaponImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'actors/arma.png',
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
    );

    weaponSprites = [
      Sprite(weaponImage, srcSize: Vector2(16, 16), srcPosition: Vector2(0, 0)),
      Sprite(weaponImage, srcSize: Vector2(16, 16), srcPosition: Vector2(16, 0)),
      Sprite(weaponImage, srcSize: Vector2(16, 16), srcPosition: Vector2(32, 0)),
      Sprite(weaponImage, srcSize: Vector2(16, 16), srcPosition: Vector2(48, 0)),
    ];

    head = SpriteComponent(
      sprite: headSprites[0],
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 2,
    );

    weapon = SpriteComponent(
      sprite: weaponSprites[0],
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 3,
    );

    addAll([body, head, weapon]);

    // --- 1. COLISOR DE COMBATE (Corpo Inteiro) ---
    playerHitbox = RectangleHitbox(
      size: Vector2(10, 16),
      anchor: Anchor.center,
      position: size / 2, 
      collisionType: CollisionType.active, 
    );
    add(playerHitbox);

    // --- 2. COLISOR DE FÍSICA (Metade da altura, fica nos pés) ---
    physicsHitbox = RectangleHitbox(
      size: Vector2(size.x, size.x * 0.5),
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, size.y / 2),
      collisionType: CollisionType.active,
    );
    add(physicsHitbox);

    // --- 3. SOMBRA VISUAL ---
    final shadowPaint = Paint()..color = Palette.preto; 
    
    final shadow = CircleComponent(
      radius: size.x / 2, 
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, size.y / 2),
      paint: shadowPaint,
      priority: -1, 
    )..scale = Vector2(1.0, 0.75);
    
    add(shadow);
  }

  @override
  void update(double dt) {
    _previousPosition = position.clone();
    super.update(dt);
    
    if (_shootTimer > 0) {
      _shootTimer -= dt;
    }

    Vector2 moveDelta = moveJoystick.relativeDelta.clone();
    if (moveDelta.isZero() && !_keyboardMove.isZero()) {
      moveDelta = _keyboardMove.normalized();
    }

    Vector2 aimDelta = aimJoystick.relativeDelta.clone();
    if (aimDelta.isZero() && !_keyboardAim.isZero()) {
      aimDelta = _keyboardAim.normalized();
    }

    bool isAiming = aimDelta.length >= 0.5;
    if (_invulnerabilityTimer > 0) {
      _invulnerabilityTimer -= dt;
      
      bool isVisible = (_invulnerabilityTimer * 10).toInt() % 2 == 0;
      double alpha = isVisible ? 1.0 : 0.2;
      
      body.setOpacity(alpha);
      head.setOpacity(alpha);
      weapon.setOpacity(isAiming ? alpha : 0.0);
    } else {
      body.setOpacity(1.0);
      head.setOpacity(1.0);
      weapon.setOpacity(isAiming ? 1.0 : 0.0);
    }
    
    _updateMovement(dt, moveDelta);
    _updateAiming(aimDelta);
  }

  void _updateMovement(double dt, Vector2 moveDelta) {
    if(naoMove){
      velocity.setZero(); 
      return;
    }
    if (!moveDelta.isZero()) {
      velocity += moveDelta * acceleration * dt;
      
      if (velocity.length > maxSpeed) {
        velocity = velocity.normalized() * maxSpeed;
      }
      
      body.playing = true; 
    } else {
      if (!velocity.isZero()) {
        double drop = friction * dt;
        
        if (velocity.length < drop) {
          velocity.setZero(); 
        } else {
          velocity -= velocity.normalized() * drop;
        }
      }
      
      if (body.playing) {
        body.playing = false;
        body.animationTicker?.currentIndex = 0;
      }
    }

    if (velocity.isZero()) return;

    position += velocity * dt;

    if (velocity.x.abs() > velocity.y.abs()) {
      if (body.animation != bodyHorizontalAnim) {
        body.animation = bodyHorizontalAnim;
      }
      if (velocity.x < 0 && !body.isFlippedHorizontally) {
        body.flipHorizontallyAroundCenter();
      } 
      else if (velocity.x > 0 && body.isFlippedHorizontally) {
        body.flipHorizontallyAroundCenter();
      }
    } else {
      if (body.animation != bodyVerticalAnim) {
        body.animation = bodyVerticalAnim;
      }
      if (body.isFlippedHorizontally) {
        body.flipHorizontallyAroundCenter();
      }
    }
  }

  void _updateAiming(Vector2 aimDelta) {
    if (aimDelta.length < 0.5) return;

    AimDirection currentAim;
    
    Vector2 weaponOffset = Vector2.zero();

    if (aimDelta.x.abs() > aimDelta.y.abs()) {
      if (aimDelta.x > 0) {
        currentAim = AimDirection.right;
        lockedFireDirection = Vector2(1, 0); 
        weaponOffset = Vector2(0, 2);        
      } else {
        currentAim = AimDirection.left;
        lockedFireDirection = Vector2(-1, 0);
        weaponOffset = Vector2(-0, 2);        
      }
    } else {
      if (aimDelta.y > 0) {
        currentAim = AimDirection.down;
        lockedFireDirection = Vector2(0, 1);
        weaponOffset = Vector2(-2, 1);        
      } else {
        currentAim = AimDirection.up;
        lockedFireDirection = Vector2(0, -1); 
        weaponOffset = Vector2(2, -1);      
      }
    }

    int targetFrameIndex = 0;
    bool needsFlip = false;
    int weaponPriority = 3; 

    switch (currentAim) {
      case AimDirection.down: 
        weaponPriority = 3; 
        targetFrameIndex = 0;
        needsFlip = false;
        weapon.position = size/2;
        break;
      case AimDirection.right: 
        weaponPriority = 0; 
        targetFrameIndex = 1;
        needsFlip = false;
        weapon.position = size/2 + Vector2(2, 0);
        break;
      case AimDirection.left: 
        weaponPriority = 3; 
        targetFrameIndex = 3;
        needsFlip = false;
        weapon.position = size/2 - Vector2(2, 0);
        break;
      case AimDirection.up: 
        weaponPriority = 0; 
        targetFrameIndex = 2;
        needsFlip = false;
        weapon.position = size/2 - Vector2(0, 3);
        break;
    }

    if (currentAimIndex != targetFrameIndex) {
      currentAimIndex = targetFrameIndex;
      head.sprite = headSprites[currentAimIndex];
      weapon.sprite = weaponSprites[currentAimIndex];
    }

    if (weapon.priority != weaponPriority) {
      weapon.priority = weaponPriority;
    }

    if (needsFlip && !head.isFlippedHorizontally) {
      head.flipHorizontallyAroundCenter();
    } else if (!needsFlip && head.isFlippedHorizontally) {
      head.flipHorizontallyAroundCenter();
    }
    if (needsFlip && !weapon.isFlippedHorizontally) {
      weapon.flipHorizontallyAroundCenter();
    } else if (!needsFlip && weapon.isFlippedHorizontally) {
      weapon.flipHorizontallyAroundCenter();
    }
    
    if (_shootTimer <= 0) {
      _shoot(lockedFireDirection, weaponOffset); 
      _shootTimer = fireRate;
    }
  }

  void _shoot(Vector2 direction, Vector2 originOffset) {
    final projectile = Projectile(
      position: position.clone() + originOffset, 
      direction: direction,
      dmg: dmg,
      kbForce: kbForce,
    );
    
    parent?.add(projectile);
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

    currentHealth -= amount;
    _invulnerabilityTimer = _invulnerabilityDuration; 

    if (currentHealth <= 0) {
      onDeath?.call();
    }
  }

  void _placeBomb() {
    if (bombsAmount > 0) {
      bombsAmount--;
      parent?.add(Bomb(position: position.clone()+(lockedFireDirection*17)));
    } else {
      print("Sem bombas!");
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardMove.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) _keyboardMove.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) _keyboardMove.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) _keyboardMove.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) _keyboardMove.y += 1;

    _keyboardAim.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) _keyboardAim.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) _keyboardAim.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) _keyboardAim.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) _keyboardAim.y += 1;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _placeBomb();
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