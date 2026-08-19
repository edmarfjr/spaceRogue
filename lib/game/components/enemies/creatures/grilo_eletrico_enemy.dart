import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Grilo Elétrico como inimigo: rápido e evasivo, mas frágil. Nunca fica
/// parado — pula pra todo lado em saltos curtos e frequentes, o que torna
/// difícil acertar, e solta faíscas rápidas entre um pulo e outro. Poucos
/// pontos de vida: acertar uma vez já resolve, o problema é acertar.
///
/// `moveAnim` null: o JumpMovement já é a animação (escreve visual.scale e
/// visual.position.y todo frame), mesmo arranjo do Sapo.
class GriloEletricoEnemy extends Enemy with JumpMovement, ShooterAttack {
  static const double _fireRate = 1.6;

  GriloEletricoEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.griloEletrico,
         moveAnim: null, // o pulo é a animação
         speed: 0.0,     // quem move é o JumpMovement
         health: 16,     // stats.maxHp 6 / defesa 1 → o mais frágil do elenco
         dmg: 2,
         bltSpeed: 130,
         bltImg: 'projeteis/tiro.png',
         bltCor1: CreatureRegistry.griloEletrico.corClara,
         bltCor2: CreatureRegistry.griloEletrico.corEscura,
         shadowOffset: Vector2(0, 3),
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupJumpAnimations(prepTime: 0.15); // agacha rapidinho: é evasivo, não telegrafado
    setupAttackAnimation(duration: 0.2);

    idleDuration = 0.25; // quase não descansa entre pulos
    airDuration = 0.3;
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, _fireRate, _faisca)) return;

    // Só atira com os pés no chão — nunca no meio do pulo.
    if (wantsToShoot && jumpState == JumpState.idle) {
      triggerAttack();
      return;
    }

    // JumpMode.random sempre: ele foge do jogador, não mira nele.
    updateJumpMovement(
      dt,
      playerTarget.absolutePosition,
      mode: JumpMode.random,
      jumpDistance: 34.0,
      jumpHeight: 16.0,
    );
  }

  void _faisca() {
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
