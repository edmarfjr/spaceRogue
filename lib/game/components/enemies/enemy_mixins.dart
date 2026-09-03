import 'dart:ui';

import 'package:flame/components.dart';
import 'dart:math';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/creatures/movement_host.dart';

// --- CÉREBRO 1: MOVIMENTO EM GRADE ---
mixin GridMovement on MovementHost {
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
mixin WanderMovement on MovementHost {
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

  bool _isDirectionValid(Vector2 dir) => direcaoLivre(dir);

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
mixin ShooterAttack on MovementHost {
  /// Som do ataque, tocado quando a premeditação começa — quem usa este
  /// mixin implementa (ver `Enemy.attackSfx`, que segue o tipo elemental da
  /// criatura, o mesmo mapa de `CreatureTypeSfx`).
  Sfx? get attackSfx;

  bool isAttacking = false;
  bool wantsToShoot = false;

  double attackTimer = 0.0;
  double attackDuration = 0.3;
  double fireTimer = 0.0;

  /// Aviso: o inimigo trava, a exclamação aparece, e só DEPOIS o ataque começa.
  /// É essa fase que dá ao jogador tempo de sair da frente — sem ela o aviso
  /// nasceria junto com o golpe e não avisaria nada.
  bool isTelegraphing = false;
  double telegraphTimer = 0.0;
  double telegraphDuration = 0.5;

  void setupAttackAnimation({double duration = 0.3, double telegraph = 0.5}) {
    attackDuration = duration;
    telegraphDuration = telegraph;
  }

  // Retorna 'true' enquanto estiver avisando ou atacando (para bloquear o movimento)
  bool updateAttack(double dt, double fireRate, Function onShootCompleted) {
    if (isTelegraphing) {
      telegraphTimer += dt;

      // Trava em escala neutra: o inimigo "para e se prepara". Ninguém mais
      // escreve scale nesta fase, já que o movimento está bloqueado.
      visual.scale = Vector2(visual.scale.x.isNegative ? -1.0 : 1.0, 1.0);

      if (telegraphTimer >= telegraphDuration) {
        isTelegraphing = false;
        telegraphTimer = 0.0;
        isAttacking = true;
        attackTimer = 0.0;
      }
      return true;
    }

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

    // Cego não mira: a direção do tiro é calculada a partir da posição do
    // jogador em cada inimigo, então a única forma honesta de "perder o alvo"
    // é não deixar a vontade de atirar amadurecer.
    if (cegoTimer > 0) {
      wantsToShoot = false;
      fireTimer = 0.0;
      return false;
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

  /// Não ataca agora: entra na fase de aviso. O tiro sai
  /// `telegraphDuration + attackDuration` segundos depois daqui.
  void triggerAttack() {
    isTelegraphing = true;
    telegraphTimer = 0.0;
    wantsToShoot = false;
    attackTimer = 0.0;

    final sfx = attackSfx;
    if (sfx != null) GameAudio.instance.play(sfx);

    spawnAlerta(duracao: telegraphDuration);
  }
}

mixin ChaseMovement on MovementHost {
  static const double _cegoTrocaDirecao = 0.7;

  final Random _cegoRandom = Random();
  Vector2 _cegoDirecao = Vector2.zero();
  double _cegoTrocaTimer = 0.0;

  void updateChaseMovement(double dt) {
    if (cegoTimer > 0) {
      _updateCegoMovement(dt);
      return;
    }

    // Calcula a distância exata entre o inimigo e o jogador
    Vector2 distanceToPlayer = currentTarget.absolutePosition - absolutePosition;
    
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

  /// Cego: perdeu o rastro do jogador e passa a vagar. Reusa a checagem de
  /// parede do Enemy — sem ela, o perseguidor cego encosta numa parede e fica
  /// raspando nela, o que lê como bug e não como cegueira.
  void _updateCegoMovement(double dt) {
    _cegoTrocaTimer -= dt;

    if (_cegoDirecao.isZero() || _cegoTrocaTimer <= 0) {
      _cegoTrocaTimer = _cegoTrocaDirecao;
      _cegoDirecao = Vector2.zero();

      for (int tentativa = 0; tentativa < 10; tentativa++) {
        final angulo = _cegoRandom.nextDouble() * 2 * pi;
        final candidata = Vector2(cos(angulo), sin(angulo));
        if (direcaoLivre(candidata)) {
          _cegoDirecao = candidata;
          break;
        }
      }
    }

    if (_cegoDirecao.isZero()) {
      animateMovement(dt, isMoving: false);
      return;
    }

    position += _cegoDirecao * speed * dt;

    if (_cegoDirecao.x < 0 && !visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    } else if (_cegoDirecao.x > 0 && visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    }

    animateMovement(dt, isMoving: true, horizontalDir: _cegoDirecao.x);
  }
}

enum JumpState { idle, preparing, inAir }

enum JumpMode { targetPlayer, random }

// --- CÉREBRO: PULO (SUBSTITUI O ANTIGO InvestidaMovement, agora removido) ---
// Sprite estático: os três estados (parado/agachando/voando) não trocam mais
// de frame — o tell visual é um agachamento por escala e um deslocamento em Y
// simulando altura, e o pulo em si continua sendo dados puros (direção/velocidade).
mixin JumpMovement on MovementHost {
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

    _baseVisualY = size.y;
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

        // Saltador tem `speed: 0.0` — quem move é o `_calculatedJumpSpeed`,
        // derivado da distância. Escalar `speed` não faria nada nele, então a
        // lentidão aparece como descanso mais longo entre um pulo e outro.
        if (jumpTimer >= idleDuration / lentidaoFator) {
          jumpState = JumpState.preparing;
          jumpTimer = 0.0;

          // Só avisa quando o pulo é um ataque de verdade (mirado no jogador).
          // Reposicionamento aleatório (JumpMode.random) não merece exclamação.
          if (mode == JumpMode.targetPlayer) spawnAlerta();
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

            // Mirar direto no jogador não garante pouso dentro da sala — com
            // o alvo perto de uma porta ou quina, o pulo saía pra fora sem
            // checagem nenhuma (só `JumpMode.random` validava, via
            // `_calculateSmartRandomTarget`). Puxa de volta na MESMA direção
            // (nunca muda de lado, só encurta o pulo) até achar um pouso
            // válido; sem nenhum no caminho, fica parado.
            finalTarget = _pousoValidoNaDirecao(finalTarget);
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

  /// Pouso [alvo] cabe dentro de [roomRect] sem cair em cima de parede,
  /// pedra ou buraco? Usa o tamanho do `physicsHitbox` centrado em [alvo] —
  /// a mesma sombra que o inimigo teria de verdade ao pousar ali — não o
  /// ponto sozinho, que passaria reto por cima de qualquer obstáculo do
  /// tamanho de um pixel.
  bool _pousoValido(Vector2 alvo, Rect roomRect) {
    final delta = alvo - absolutePosition;
    final futureCenter = physicsHitbox.absoluteCenter + delta;
    final futureRect = Rect.fromCenter(
      center: Offset(futureCenter.x, futureCenter.y),
      width: physicsHitbox.size.x,
      height: physicsHitbox.size.y,
    );

    if (futureRect.left < roomRect.left ||
        futureRect.top < roomRect.top ||
        futureRect.right > roomRect.right ||
        futureRect.bottom > roomRect.bottom) {
      return false;
    }

    for (final child in roomColliders) {
      if (child.toAbsoluteRect().overlaps(futureRect)) return false;
    }
    return true;
  }

  // --- I.A. PREDITIVA PARA O PONTO DE POUSO ---
  Vector2 _calculateSmartRandomTarget(double dist) {
    final room = currentRoom;
    // Sem sala identificada (ex.: bem em cima da borda, por causa do Rect.contains
    // ser exclusivo), não pula às cegas — fica parado até a próxima chamada.
    if (room == null) return absolutePosition;

    final Rect roomRect = room.toAbsoluteRect();

    for (int attempts = 0; attempts < 10; attempts++) {
      final angle = _jumpRandom.nextDouble() * 2 * pi;
      final testTarget = absolutePosition + Vector2(cos(angle), sin(angle)) * dist;

      // Se passou pelas bordas da sala e pelos colisores, é um pouso válido!
      if (_pousoValido(testTarget, roomRect)) return testTarget;
    }

    return absolutePosition;
  }

  /// Mesma validação de `_calculateSmartRandomTarget`, mas pra um alvo já
  /// escolhido (mirado no jogador, `JumpMode.targetPlayer`) em vez de um
  /// ângulo sorteado — não dá pra trocar de direção, só encurtar o pulo até
  /// caber. Puxa [alvoDesejado] de volta pra `absolutePosition` em passos de
  /// 10% e devolve o primeiro pouso válido; sem nenhum no caminho (sala não
  /// identificada, ou o próprio ponto de partida já inválido — não deveria
  /// acontecer), fica parado.
  Vector2 _pousoValidoNaDirecao(Vector2 alvoDesejado) {
    final room = currentRoom;
    if (room == null) return absolutePosition;

    final roomRect = room.toAbsoluteRect();
    if (_pousoValido(alvoDesejado, roomRect)) return alvoDesejado;

    for (int passo = 9; passo >= 1; passo--) {
      final candidato = absolutePosition + (alvoDesejado - absolutePosition) * (passo / 10);
      if (_pousoValido(candidato, roomRect)) return candidato;
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