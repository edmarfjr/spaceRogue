import 'package:flame/components.dart';
import 'package:spacerogue/game/components/creatures/creature_registry.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Sapo de Água como inimigo: pula de um lado pro outro e cospe um jato ao
/// pousar. Só movimento e ataque — nada de bolha defensiva, diferente da
/// versão jogável. Pressão de alvo que não fica parado.
///
/// `moveAnim` fica null porque o JumpMovement já É a animação: ele escreve
/// visual.scale e visual.position.y todo frame, e um MovementAnimator por cima
/// disputaria os mesmos canais.
class SapoAguaEnemy extends Enemy with JumpMovement, ShooterAttack {
  static const double _fireRate = 2.0;

  SapoAguaEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.sapoAgua,
         moveAnim: null, // o pulo é a animação
         speed: 0.0,     // quem move é o JumpMovement, não a speed
         health: 40,
         dmg: 1,
         bltSpeed: 80,
         bltImg: 'projeteis/proj1.png',
         bltCor1: CreatureRegistry.sapoAgua.corClara,
         bltCor2: CreatureRegistry.sapoAgua.corEscura,
         shadowOffset: Vector2(0, 3),
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupJumpAnimations(prepTime: 0.3);
    setupAttackAnimation(duration: 0.3);

    idleDuration = 1.1;
    airDuration = 0.45;
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, _fireRate, _cuspirJato)) return;

    // Só atira com os pés no chão — nunca no meio do pulo.
    if (wantsToShoot && jumpState == JumpState.idle) {
      triggerAttack();
      return;
    }

    updateJumpMovement(
      dt,
      playerTarget.absolutePosition,
      mode: JumpMode.random,
      jumpDistance: 20.0,
      jumpHeight: 14.0,
    );
  }

  void _cuspirJato() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is WallBarrier || other is Obstacle) {
      if (!isPhysicsCollision(other)) return;
      cancelJump();
    }
  }
}
