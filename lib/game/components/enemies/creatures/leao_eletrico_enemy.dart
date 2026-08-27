import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Leão Elétrico como inimigo: persegue e crava estocadas relâmpago de curto
/// alcance quando fecha distância — cavaleiro que caça, não atirador parado.
class LeaoEletricoEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _fireRate = 1.6;
  static const double _alcanceTiro = 55.0;

  LeaoEletricoEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.leaoEletrico,
         speed: 40.0, // stats.speed 55 → o mais veloz perseguidor do elenco
         health: 26,  // stats.maxHp 20 / defesa 4 → aguenta a corrida
         dmg: 3,
         bltSpeed: 140,
         bltImg: 'projeteis/proj2.png',
         bltCor1: CreatureRegistry.leaoEletrico.corClara,
         bltCor2: CreatureRegistry.leaoEletrico.corEscura,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.25, telegraph: 0.35);
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, _fireRate, _estocar)) return;

    if (wantsToShoot) {
      final distancia = (playerTarget.absolutePosition - absolutePosition).length;
      if (distancia <= _alcanceTiro) {
        triggerAttack();
        return;
      }
    }

    updateChaseMovement(dt);
  }

  void _estocar() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao, lifeTime: 1.2);
  }
}
