import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Ave Neutro como inimigo: persegue sem parar e dispara bicadas fracas e
/// rápidas de curto alcance. Voa — atravessa pedra e buraco, igual à Ave
/// Elétrica, só que sem elemento nenhum no bico.
class AveNeutroEnemy extends Enemy with ShooterAttack {
  static const double _fireRate = 1.4;
  static const double _alcanceTiro = 0.3;

  AveNeutroEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.aveNeutro,
        speed: 32.0,
        health: 20,
        dmg: 1,
        bltSpeed: 130,
        bltImg: 'projeteis/proj2.png',
        bltCor1: CreatureRegistry.aveNeutro.corClara,
        bltCor2: CreatureRegistry.aveNeutro.corEscura,
        isAirborne: true, // passa por cima de pedra e buraco
        shadowOffset: Vector2(0, 6),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.2);
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, _fireRate, _bicar)) return;

    if (wantsToShoot) {
      final distancia =
          (playerTarget.absolutePosition - absolutePosition).length;
      if (distancia <= 45.0) {
        triggerAttack();
        return;
      }
    }

    updateChaseMovement(dt);
  }

  void _bicar() {
    final direcao = (playerTarget.absolutePosition - absolutePosition)
        .normalized();
    shoot(direcao, lifeTime: _alcanceTiro);
  }
}
