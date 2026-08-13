import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
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

  // Animações do corpo
  late final SpriteAnimation bodyVerticalAnim;
  late final SpriteAnimation bodyHorizontalAnim;

  late final List<Sprite> headSprites;
  late final List<Sprite> weaponSprites;

  // Paint configurado para Pixel Art perfeito (sem suavização)
  final pixelArtPaint = Paint()..filterQuality = FilterQuality.none;

  // Velocidade de movimento
  double speed = 60.0;

  int currentAimIndex = 0;

  double fireRate = 0.35; // Tempo em segundos entre cada tiro
  double _shootTimer = 0.0;     // Cronômetro atual

  double dmg = 1;

  Color corClara;
  Color corEscura;

  Vector2 _keyboardMove = Vector2.zero();
  Vector2 _keyboardAim = Vector2.zero();

  // VARIÁVEIS DE VIDA
  int maxHealth = 4;
  int currentHealth = 4;

  // VARIÁVEIS DE IMUNIDADE (I-Frames)
  double _invulnerabilityTimer = 0.0;
  final double _invulnerabilityDuration = 1.5; // 1.5 segundos piscando

  int bombsAmount = 3;

  Vector2 _velocity = Vector2.zero(); 

  final double maxSpeed = 50.0;       
  final double acceleration = 100.0;  
  final double friction = 200.0;

  Player({
    required this.moveJoystick, 
    required this.aimJoystick,  
    this.corClara = Palette.vermelho, // Sua cor para o Cinza Claro
    this.corEscura = Palette.azul, // Sua cor para o Cinza Escuro
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
    
    // 2. Corpo Horizontal
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
      paint: pixelArtPaint,
      priority: 1,
    );

    // 2. Carregando as imagens completas de Cabeça e Arma
    final ui.Image headImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'actors/cabeca.png',
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
    );

    // --- NOVA ABORDAGEM: Criando as listas com os 3 recortes ---
    // Índice 0 = Baixo (X=0), Índice 1 = Direita (X=16), Índice 2 = Cima (X=32)
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

    // Inicializa os componentes apontando para o índice 0 (Baixo)
    head = SpriteComponent(
      sprite: headSprites[0],
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: pixelArtPaint,
      priority: 2,
    );

    weapon = SpriteComponent(
      sprite: weaponSprites[0],
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: pixelArtPaint,
      priority: 3,
    );

    addAll([body, head, weapon]);

    add(RectangleHitbox(
      size: Vector2(10, 10),
      anchor: Anchor.center,
      position: size / 2, // Centraliza a hitbox no personagem
      collisionType: CollisionType.active, // O jogador é "ativo" e procura colisões
    ));
  }

  @override
  void update(double dt) {
    _previousPosition = position.clone();
    super.update(dt);
    if (_shootTimer > 0) {
      _shootTimer -= dt;
    }
    if (_invulnerabilityTimer > 0) {
      _invulnerabilityTimer -= dt;
      
      // Faz o personagem piscar (alterna a opacidade 10 vezes por segundo)
      bool isVisible = (_invulnerabilityTimer * 10).toInt() % 2 == 0;
      double alpha = isVisible ? 1.0 : 0.2;
      
      body.setOpacity(alpha);
      head.setOpacity(alpha);
    } else {
      // Garante que a opacidade volte ao normal quando a imunidade acabar
      body.setOpacity(1.0);
      head.setOpacity(1.0);
    }
    
    // --- NOVA LÓGICA: CONSOLIDAÇÃO DE INPUTS ---
    Vector2 moveDelta = moveJoystick.relativeDelta.clone();
    // Se o joystick da tela estiver solto e o teclado estiver sendo usado
    if (moveDelta.isZero() && !_keyboardMove.isZero()) {
      moveDelta = _keyboardMove.normalized();
    }

    Vector2 aimDelta = aimJoystick.relativeDelta.clone();
    // Mesma coisa para a mira
    if (aimDelta.isZero() && !_keyboardAim.isZero()) {
      aimDelta = _keyboardAim.normalized();
    }

    // Repassamos os vetores calculados para as funções
    _updateMovement(dt, moveDelta);
    _updateAiming(aimDelta);
  }

  void _updateMovement(double dt, Vector2 moveDelta) {
    // 1. APLICAÇÃO DE FORÇAS (Aceleração vs Atrito)
    if (!moveDelta.isZero()) {
      // Se o jogador está pressionando o controle, acelera na direção apontada
      _velocity += moveDelta * acceleration * dt;
      
      // Limita para não ultrapassar a velocidade máxima
      if (_velocity.length > maxSpeed) {
        _velocity = _velocity.normalized() * maxSpeed;
      }
      
      body.playing = true; // Anima as perninhas
    } else {
      // Se soltou o controle, aplica o atrito (freio) gradualmente
      if (!_velocity.isZero()) {
        double drop = friction * dt; // Quantidade de freio neste frame
        
        if (_velocity.length < drop) {
          _velocity.setZero(); // Parou totalmente
        } else {
          // Subtrai o atrito da velocidade atual, mantendo a direção da derrapada
          _velocity -= _velocity.normalized() * drop;
        }
      }
      
      // Igual ao Isaac: quando solta o controle, as pernas param na hora, 
      // mas o corpo continua derrapando pela inércia.
      if (body.playing) {
        body.playing = false;
        body.animationTicker?.currentIndex = 0;
      }
    }

    // Se está totalmente parado, não precisa processar o resto
    if (_velocity.isZero()) return;

    // 2. APLICA A VELOCIDADE NA POSIÇÃO
    position += _velocity * dt;

    // 3. ANIMAÇÃO DIREACIONAL (Baseada na inércia, não no input)
    if (_velocity.x.abs() > _velocity.y.abs()) {
      // Movimento predominante horizontal
      if (body.animation != bodyHorizontalAnim) {
        body.animation = bodyHorizontalAnim;
      }
      if (_velocity.x < 0 && !body.isFlippedHorizontally) {
        body.flipHorizontallyAroundCenter();
      } 
      else if (_velocity.x > 0 && body.isFlippedHorizontally) {
        body.flipHorizontallyAroundCenter();
      }
    } else {
      // Movimento predominante vertical
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
    Vector2 lockedFireDirection = Vector2.zero();
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
        weaponOffset = Vector2(-3, 1);        
      } else {
        currentAim = AimDirection.up;
        lockedFireDirection = Vector2(0, -1); 
        weaponOffset = Vector2(3, -1);     
      }
    }

    int targetFrameIndex = 0;
    bool needsFlip = false;
    int weaponPriority = 3; 

    switch (currentAim) {
      case AimDirection.down: 
        targetFrameIndex = 0;
        needsFlip = false;
        weaponPriority = 3; 
        break;
      case AimDirection.right: 
        targetFrameIndex = 1;
        needsFlip = false;
        weaponPriority = 3; 
        break;
      case AimDirection.left: 
        targetFrameIndex = 3;
        needsFlip = false;
        weaponPriority = 3; 
        break;
      case AimDirection.up: 
        targetFrameIndex = 2;
        needsFlip = false;
        weaponPriority = 0; 
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
    
    // -----------------------------------------------------

    if (_shootTimer <= 0) {
      _shoot(lockedFireDirection, weaponOffset); 
      _shootTimer = fireRate;
    }
  }

  void _shoot(Vector2 direction, Vector2 originOffset) {
    final projectile = Projectile(
      position: position.clone() + originOffset, 
      direction: direction,
    );
    
    parent?.add(projectile);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Enemy) {
      takeDamage(1);
    }
    
    if (other is WallBarrier || other is Obstacle) {
      Vector2 collisionCenter = Vector2.zero();
      for (var point in intersectionPoints) {
        collisionCenter += point;
      }
      collisionCenter /= intersectionPoints.length.toDouble();

      Vector2 diff = absolutePosition - collisionCenter;
      
      if (diff.x.abs() > diff.y.abs()) {
        position.x = _previousPosition.x;
        _velocity.x = 0; 
      } else {
        position.y = _previousPosition.y;
        _velocity.y = 0; 
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
      parent?.add(Bomb(position: position.clone()));
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