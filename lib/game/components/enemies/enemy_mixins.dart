import 'dart:ui';

import 'package:flame/components.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'dart:math';
import 'enemy.dart'; // Importe sua classe base

// --- CÉREBRO 1: MOVIMENTO EM GRADE ---
mixin GridMovement on Enemy {
  Vector2? targetPosition;
  Vector2? startPosition;
  double pauseTimer = 0.0;
  final Random _random = Random();

  void updateGridMovement(double dt, {double pauseDuration = 0.4, double tileSize = 16.0}) {
    if (targetPosition == null) {
      pauseTimer += dt;
      if (pauseTimer >= pauseDuration) {
        pauseTimer = 0.0;
        _pickNewTarget(tileSize);
      }
    } else {
      Vector2 direction = targetPosition! - position;
      double distanceToMove = speed * dt;

      if (direction.length < distanceToMove) {
        position = targetPosition!.clone();
        targetPosition = null;
      } else {
        position += direction.normalized() * distanceToMove;
        
        if (direction.x < 0 && !visual.isFlippedHorizontally) {
          visual.flipHorizontallyAroundCenter();
        } else if (direction.x > 0 && visual.isFlippedHorizontally) {
          visual.flipHorizontallyAroundCenter();
        }
      }
    }
  }

  void _pickNewTarget(double tileSize) {
    List<Vector2> directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)];
    Vector2 chosenDir = directions[_random.nextInt(4)];
    startPosition = position.clone();
    targetPosition = position + (chosenDir * tileSize);
  }

  // Realinha o inimigo na grade caso sofra knockback
  void alignToGrid(double tileSize) {
    double snapX = (position.x / tileSize).floorToDouble() * tileSize + (tileSize / 2);
    double snapY = (position.y / tileSize).floorToDouble() * tileSize + (tileSize / 2);
    targetPosition = Vector2(snapX, snapY);
    startPosition = position.clone();
  }
}

// --- CÉREBRO 2: MOVIMENTO LIVRE/VAGANTE ---
mixin WanderMovement on Enemy {
  double moveTimer = 0.0;
  double pauseTimer = 0.0;
  bool isMoving = false;
  Vector2 currentDirection = Vector2.zero();
  final Random _random = Random();

  void updateWanderMovement(double dt, {double minPause = 0.5, double maxPause = 1.5, double minMove = 1.0, double maxMove = 2.5}) {
    if (isMoving) {
      moveTimer -= dt;
      position += currentDirection * speed * dt;

      if (currentDirection.x < 0 && !visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      } else if (currentDirection.x > 0 && visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      }

      if (moveTimer <= 0) {
        isMoving = false;
        pauseTimer = minPause + _random.nextDouble() * (maxPause - minPause);
      }
    } else {
      pauseTimer -= dt;
      if (pauseTimer <= 0) {
        _pickRandomDirection(minMove, maxMove);
      }
    }
  }

  void _pickRandomDirection(double minMove, double maxMove) {
    int attempts = 0;
    double angle = 0;
    Vector2 testDirection = Vector2.zero();
    
    // Tenta achar uma direção limpa (sem paredes) em até 10 tentativas
    while (attempts < 10) {
      angle = _random.nextDouble() * 2 * pi;
      testDirection = Vector2(cos(angle), sin(angle)).normalized();
      
      if (_isDirectionValid(testDirection)) {
        break; // O caminho está livre! Sai do loop.
      }
      attempts++;
    }
    
    currentDirection = testDirection;
    moveTimer = minMove + _random.nextDouble() * (maxMove - minMove);
    isMoving = true;
  }

  // --- NOVA FUNÇÃO DE PREVISÃO DO FUTURO ---
  bool _isDirectionValid(Vector2 dir) {
    if (parent == null) return true; // Segurança caso ele não esteja na tela ainda

    // Projeta a sombra imaginária para o que aconteceria daqui a 0.6 segundos
    double lookAheadDistance = speed * 0.6; 
    
    // Calcula o centro do futuro
    Vector2 futureCenter = physicsHitbox.absoluteCenter + (dir * lookAheadDistance);
    
    // Cria um retângulo simulando a hitbox de física lá no futuro
    Rect futureRect = Rect.fromCenter(
      center: Offset(futureCenter.x, futureCenter.y),
      width: physicsHitbox.size.x,
      height: physicsHitbox.size.y,
    );

    // Vasculha todos os objetos da sala
    for (var child in parent!.children.whereType<PositionComponent>()) {
      
      if (child is WallBarrier || child is Obstacle) {
        
        if (isAirborne && child is Obstacle) continue;
        
        // Agora o Dart reconhece perfeitamente o toAbsoluteRect() !
        if (child.toAbsoluteRect().overlaps(futureRect)) {
          return false; 
        }
      }
    }
    
    return true; // Se o loop terminou sem bater em nada, a direção é perfeita!
  }

  void cancelWander() {
    if (isMoving && knockbackVelocity.isZero()) {
      isMoving = false;
      pauseTimer = 0.2; 
      currentDirection = Vector2.zero();
    }
  }
}

// --- CÉREBRO 3: ATIRADOR COM ANIMAÇÃO ---
mixin ShooterAttack on Enemy {
  late SpriteAnimation moveAnimation;
  late SpriteAnimation attackAnimation;

  bool isAttacking = false;
  bool wantsToShoot = false;
  
  double attackTimer = 0.0;
  late double attackDuration;
  double fireTimer = 0.0;

  void setupAttackAnimation({required int frames, required double frameTime, required Vector2 textureSize, required Vector2 texturePosition}) {
    moveAnimation = visual.animation!;
    attackDuration = (frames - 1) * frameTime;

    final swappedImage = visual.animation!.frames.first.sprite.image;
    attackAnimation = SpriteAnimation.fromFrameData(
      swappedImage,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: frameTime,
        textureSize: textureSize,
        texturePosition: texturePosition,
        loop: false,
      ),
    );
  }

  // Retorna 'true' enquanto estiver atacando (para bloquear o movimento)
  bool updateAttack(double dt, double fireRate, Function onShootCompleted) {
    if (isAttacking) {
      attackTimer += dt;
      if (attackTimer >= attackDuration) {
        onShootCompleted(); 
        isAttacking = false;
        attackTimer = 0.0;
        visual.animation = moveAnimation;
      }
      return true; 
    }

    if (!wantsToShoot) {
      fireTimer += dt;
      if (fireTimer >= fireRate) {
        wantsToShoot = true;
        fireTimer = 0.0;
      }
    }
    return false;
  }

  void triggerAttack() {
    isAttacking = true;
    wantsToShoot = false;
    visual.animation = attackAnimation;
    visual.animationTicker?.reset();
  }
}

mixin ChaseMovement on Enemy {
  void updateChaseMovement(double dt) {
    // Calcula a distância exata entre o inimigo e o jogador
    Vector2 distanceToPlayer = playerTarget.absolutePosition - absolutePosition;
    
    // Evita tremedeira caso ele consiga chegar exatamente no mesmo pixel do jogador
    if (distanceToPlayer.length > 1.0) {
      Vector2 direction = distanceToPlayer.normalized();
      
      // Anda na direção do jogador
      position += direction * speed * dt;
      
      // Espelha o sprite para olhar para o jogador
      if (direction.x < 0 && !visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      } else if (direction.x > 0 && visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      }
    }
  }
}

enum JumpState { idle, preparing, inAir }

mixin InvestidaMovement on Enemy {
  JumpState jumpState = JumpState.idle;
  double jumpTimer = 0.0;

  late SpriteAnimation idleAnim;
  late SpriteAnimation prepAnim;
  late SpriteAnimation airAnim;

  late double prepDuration;
  double airDuration = 0.4;  // Tempo de duração do pulo
  double idleDuration = 1.0; // Tempo parado respirando

  Vector2 jumpDirection = Vector2.zero();

  void setupJumpAnimations({
    required SpriteAnimation idle,
    required SpriteAnimation prep,
    required SpriteAnimation air,
    required double prepTime,
  }) {
    idleAnim = idle;
    prepAnim = prep;
    airAnim = air;
    prepDuration = prepTime;
    
    // Começa no estado idle
    visual.animation = idleAnim;
  }

  void updateJumpMovement(double dt, Vector2 targetPos, {double jumpSpeed = 120.0}) {
    jumpTimer += dt;

    switch (jumpState) {
      
      // 1. ESTADO PARADO (IDLE)
      case JumpState.idle:
        if (jumpTimer >= idleDuration) {
          jumpState = JumpState.preparing;
          jumpTimer = 0.0;
          
          visual.animation = prepAnim;
          visual.animationTicker?.reset(); // Garante que a animação rode desde o frame 0
        }
        break;

      // 2. ESTADO DE PREPARAÇÃO (AGACHANDO)
      case JumpState.preparing:
        // A duração da preparação é exatamente o tempo da animação tocar inteira
        if (jumpTimer >= prepDuration) {
          jumpState = JumpState.inAir;
          jumpTimer = 0.0;
          
          visual.animation = airAnim; // Troca pro sprite voando
          
          // Trava a direção na qual ele vai pular (na direção do alvo)
          Vector2 distance = targetPos - absolutePosition;
          if (distance.length > 0) {
            jumpDirection = distance.normalized();
            
            // Espelha o sprite
            if (jumpDirection.x < 0 && !visual.isFlippedHorizontally) {
              visual.flipHorizontallyAroundCenter();
            } else if (jumpDirection.x > 0 && visual.isFlippedHorizontally) {
              visual.flipHorizontallyAroundCenter();
            }
          } else {
            jumpDirection = Vector2.zero();
          }
        }
        break;

      // 3. ESTADO NO AR (MOVENDO)
      case JumpState.inAir:
        // Somente aqui ele altera a posição física (X, Y)
        position += jumpDirection * jumpSpeed * dt;
        
        // Quando o tempo de voo acaba, ele "cai" no chão
        if (jumpTimer >= airDuration) {
          jumpState = JumpState.idle;
          jumpTimer = 0.0;
          visual.animation = idleAnim;
          jumpDirection = Vector2.zero();
        }
        break;
    }
  }

  // Aborta o salto e cai no chão se bater a cabeça numa parede
  void cancelJump() {
    if (jumpState == JumpState.inAir && knockbackVelocity.isZero()) {
      jumpState = JumpState.idle;
      jumpTimer = 0.0;
      visual.animation = idleAnim;
      jumpDirection = Vector2.zero();
    }
  }
}

enum JumpMode { targetPlayer, random }

mixin JumpMovement on Enemy {
  JumpState jumpState = JumpState.idle;
  double jumpTimer = 0.0;

  late SpriteAnimation idleAnim;
  late SpriteAnimation prepAnim;
  late SpriteAnimation airAnim;

  late double prepDuration;
  double airDuration = 0.4;  
  double idleDuration = 1.0; 

  Vector2 jumpDirection = Vector2.zero();
  
  late double _baseVisualY;
  late double _baseHitboxY; 
  
  double _calculatedJumpSpeed = 0.0;
  final Random _jumpRandom = Random();

  void setupJumpAnimations({
    required SpriteAnimation idle,
    required SpriteAnimation prep,
    required SpriteAnimation air,
    required double prepTime,
  }) {
    idleAnim = idle;
    prepAnim = prep;
    airAnim = air;
    prepDuration = prepTime;
    
    visual.animation = idleAnim;
    
    _baseVisualY = size.y / 2; 
    _baseHitboxY = enemyHitbox.position.y; 
  }

  void updateJumpMovement(
    double dt, 
    Vector2 playerPos, {
    JumpMode mode = JumpMode.targetPlayer,
    double? jumpDistance, 
    double jumpHeight = 24.0,
  }) {
    jumpTimer += dt;

    switch (jumpState) {
      
      case JumpState.idle:
        isAirborne = false;
        visual.position.y = _baseVisualY; 
        enemyHitbox.position.y = _baseHitboxY; 
        if (jumpTimer >= idleDuration) {
          jumpState = JumpState.preparing;
          jumpTimer = 0.0;
          visual.animation = prepAnim;
          visual.animationTicker?.reset(); 
        }
        break;

      case JumpState.preparing:
        isAirborne = false;
        visual.position.y = _baseVisualY; 
        enemyHitbox.position.y = _baseHitboxY; 
        
        if (jumpTimer >= prepDuration) {
          jumpState = JumpState.inAir;
          jumpTimer = 0.0;
          visual.animation = airAnim; 
          
          Vector2 finalTarget;
          
          if (mode == JumpMode.targetPlayer) {
            finalTarget = playerPos.clone();
            
            if (jumpDistance != null) {
              Vector2 distVec = finalTarget - absolutePosition;
              if (distVec.length > jumpDistance) {
                finalTarget = absolutePosition + distVec.normalized() * jumpDistance;
              }
            }
          } else {
            // MÁGICA: Pulo aleatório agora usa Inteligência Artificial
            double dist = jumpDistance ?? 60.0;
            finalTarget = _calculateSmartRandomTarget(dist);
          }

          Vector2 distanceVec = finalTarget - absolutePosition;
          if (distanceVec.length > 0) {
            jumpDirection = distanceVec.normalized();
            _calculatedJumpSpeed = distanceVec.length / airDuration; 

            if (jumpDirection.x < 0 && !visual.isFlippedHorizontally) {
              visual.flipHorizontallyAroundCenter();
            } else if (jumpDirection.x > 0 && visual.isFlippedHorizontally) {
              visual.flipHorizontallyAroundCenter();
            }
          } else {
            jumpDirection = Vector2.zero();
            _calculatedJumpSpeed = 0.0;
          }
        }
        break;

      case JumpState.inAir:
        isAirborne = true;
        
        position += jumpDirection * _calculatedJumpSpeed * dt;
        
        double progress = jumpTimer / airDuration; 
        double zOffset = 4 * jumpHeight * progress * (1 - progress);
        
        visual.position.y = _baseVisualY - zOffset; 
        enemyHitbox.position.y = _baseHitboxY - zOffset; 
        
        if (jumpTimer >= airDuration) {
          jumpState = JumpState.idle;
          jumpTimer = 0.0;
          visual.animation = idleAnim;
          
          visual.position.y = _baseVisualY; 
          enemyHitbox.position.y = _baseHitboxY; 
          jumpDirection = Vector2.zero();
        }
        break;
    }
  }

  // --- I.A. PREDITIVA PARA O PONTO DE POUSO ---
  Vector2 _calculateSmartRandomTarget(double dist) {
    if (parent == null) return absolutePosition + Vector2(1, 0) * dist;

    int attempts = 0;
    Vector2 testTarget = absolutePosition;
    
    // Descobre a largura e altura total da sala atual!
    Vector2 roomSize = (parent is PositionComponent) 
        ? (parent as PositionComponent).size 
        : Vector2(9999, 9999); // Fallback de segurança

    while (attempts < 10) {
      double angle = _jumpRandom.nextDouble() * 2 * pi;
      testTarget = absolutePosition + Vector2(cos(angle), sin(angle)) * dist;
      
      Vector2 delta = testTarget - absolutePosition;
      Vector2 futureCenter = physicsHitbox.absoluteCenter + delta;
      
      Rect futureRect = Rect.fromCenter(
        center: Offset(futureCenter.x, futureCenter.y),
        width: physicsHitbox.size.x,
        height: physicsHitbox.size.y,
      );

      bool isValid = true;

      // 1. CHECAGEM DE BORDAS DA SALA (Limites Absolutos)
      // A sombra imaginária vazou da sala (esquerda, cima, direita ou baixo)?
      if (futureRect.left < 0 || futureRect.top < 0 || 
          futureRect.right > roomSize.x || futureRect.bottom > roomSize.y) {
        isValid = false; 
      }

      // 2. CHECAGEM DE COLISÕES INTERNAS (Pedras, Paredes e Buracos)
      if (isValid) {
        for (var child in parent!.children.whereType<PositionComponent>()) {
          if (child is WallBarrier || child is Obstacle) {
            if (child.toAbsoluteRect().overlaps(futureRect)) {
              isValid = false;
              break; 
            }
          }
        }
      }

      // Se passou pelas Bordas E pelas Paredes, é um local de pouso perfeito!
      if (isValid) {
        return testTarget; 
      }
      
      attempts++;
    }
    
    return absolutePosition; 
  }

  void cancelJump() {
    if (jumpState == JumpState.inAir && knockbackVelocity.isZero()) {
      jumpState = JumpState.idle;
      jumpTimer = 0.0;
      visual.animation = idleAnim;
      
      visual.position.y = _baseVisualY; 
      enemyHitbox.position.y = _baseHitboxY; 
      jumpDirection = Vector2.zero();
    }
  }
}