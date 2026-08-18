import 'dart:ui';

import 'package:flame/components.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
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
      animateMovement(dt, isMoving: true, horizontalDir: currentDirection.x);
    } else {
      pauseTimer -= dt;
      if (pauseTimer <= 0) {
        _pickRandomDirection(minMove, maxMove);
      }
      animateMovement(dt, isMoving: false);
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
    final room = currentRoom;
    if (room == null) return true; // Segurança caso ele não esteja na tela ainda

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

    // Vasculha os corpos sólidos da SALA (paredes e obstáculos são filhos dela)
    for (final child in roomColliders) {
      if (isAirborne && child is Obstacle) continue;

      if (child.toAbsoluteRect().overlaps(futureRect)) {
        return false;
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

// --- CÉREBRO 3: ATIRADOR ---
// Sprite estático: não há mais spritesheet de ataque pra trocar de frame.
// O tell visual do ataque é um pulso de escala (esticar/espremer) em vez de animação.
mixin ShooterAttack on Enemy {
  bool isAttacking = false;
  bool wantsToShoot = false;

  double attackTimer = 0.0;
  double attackDuration = 0.3;
  double fireTimer = 0.0;

  void setupAttackAnimation({double duration = 0.3}) {
    attackDuration = duration;
  }

  // Retorna 'true' enquanto estiver atacando (para bloquear o movimento)
  bool updateAttack(double dt, double fireRate, Function onShootCompleted) {
    if (isAttacking) {
      attackTimer += dt;

      // Preserva o sinal de scale.x — é ele que guarda o flip horizontal.
      // Sem isso, o inimigo virado pra esquerda voltava a olhar pra direita
      // a cada tiro.
      final flip = visual.scale.x.isNegative ? -1.0 : 1.0;

      double progress = (attackTimer / attackDuration).clamp(0.0, 1.0);
      double pulse = 1.0 + 0.25 * (1 - (progress * 2 - 1).abs());
      visual.scale = Vector2(pulse * flip, 2.0 - pulse);

      if (attackTimer >= attackDuration) {
        onShootCompleted();
        isAttacking = false;
        attackTimer = 0.0;
        visual.scale = Vector2(flip, 1.0);
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
    attackTimer = 0.0;
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

      animateMovement(dt, isMoving: true, horizontalDir: direction.x);
    } else {
      animateMovement(dt, isMoving: false);
    }
  }
}

enum JumpState { idle, preparing, inAir }

enum JumpMode { targetPlayer, random }

// --- CÉREBRO: PULO (SUBSTITUI O ANTIGO InvestidaMovement, agora removido) ---
// Sprite estático: os três estados (parado/agachando/voando) não trocam mais
// de frame — o tell visual é um agachamento por escala e um deslocamento em Y
// simulando altura, e o pulo em si continua sendo dados puros (direção/velocidade).
mixin JumpMovement on Enemy {
  JumpState jumpState = JumpState.idle;
  double jumpTimer = 0.0;

  double prepDuration = 0.3;
  double airDuration = 0.4;
  double idleDuration = 1.0;

  Vector2 jumpDirection = Vector2.zero();

  late double _baseVisualY;
  late double _baseHitboxY;

  double _calculatedJumpSpeed = 0.0;
  final Random _jumpRandom = Random();

  void setupJumpAnimations({double prepTime = 0.3}) {
    prepDuration = prepTime;

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

    // Preserva o sinal de scale.x — é ele que guarda o flip horizontal.
    final flip = visual.scale.x.isNegative ? -1.0 : 1.0;

    switch (jumpState) {

      case JumpState.idle:
        isAirborne = false;
        visual.position.y = _baseVisualY;
        visual.scale = Vector2(flip, 1.0);
        enemyHitbox.position.y = _baseHitboxY;
        if (jumpTimer >= idleDuration) {
          jumpState = JumpState.preparing;
          jumpTimer = 0.0;
        }
        break;

      case JumpState.preparing:
        isAirborne = false;
        visual.position.y = _baseVisualY;
        enemyHitbox.position.y = _baseHitboxY;

        // Agacha progressivamente até o momento do salto
        double prepProgress = (jumpTimer / prepDuration).clamp(0.0, 1.0);
        visual.scale = Vector2((1.0 + prepProgress * 0.2) * flip, 1.0 - prepProgress * 0.2);

        if (jumpTimer >= prepDuration) {
          jumpState = JumpState.inAir;
          jumpTimer = 0.0;

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
        // Estica levemente no ar, oposto ao agachamento da preparação
        visual.scale = Vector2(0.9 * flip, 1.1);

        if (jumpTimer >= airDuration) {
          jumpState = JumpState.idle;
          jumpTimer = 0.0;
          visual.scale = Vector2(flip, 1.0);

          visual.position.y = _baseVisualY;
          enemyHitbox.position.y = _baseHitboxY;
          jumpDirection = Vector2.zero();
        }
        break;
    }
  }

  // --- I.A. PREDITIVA PARA O PONTO DE POUSO ---
  Vector2 _calculateSmartRandomTarget(double dist) {
    final room = currentRoom;
    // Sem sala identificada (ex.: bem em cima da borda, por causa do Rect.contains
    // ser exclusivo), não pula às cegas — fica parado até a próxima chamada.
    if (room == null) return absolutePosition;

    int attempts = 0;
    Vector2 testTarget = absolutePosition;

    // Limites reais da sala atual, em coordenadas absolutas do mundo
    final Rect roomRect = room.toAbsoluteRect();

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
      if (futureRect.left < roomRect.left || futureRect.top < roomRect.top ||
          futureRect.right > roomRect.right || futureRect.bottom > roomRect.bottom) {
        isValid = false;
      }

      // 2. CHECAGEM DE COLISÕES INTERNAS (Pedras, Paredes e Buracos)
      if (isValid) {
        for (final child in roomColliders) {
          if (child.toAbsoluteRect().overlaps(futureRect)) {
            isValid = false;
            break;
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
      visual.scale = Vector2(visual.scale.x.isNegative ? -1.0 : 1.0, 1.0);

      visual.position.y = _baseVisualY;
      enemyHitbox.position.y = _baseHitboxY;
      jumpDirection = Vector2.zero();
    }
  }
}