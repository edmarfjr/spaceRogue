import 'package:flame/components.dart';
import 'package:spacerogue/game/components/creatures/creature_registry.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Ave de Eletricidade como inimigo: persegue sem parar e dispara bicadas
/// fracas e rápidas de curto alcance. Voa — é o único que atravessa pedras e
/// buracos, então não dá pra usar o cenário como escudo contra ela.
///
/// `flutuar` é a única animação de movimento que não escreve visual.scale,
/// por isso combina com o pulso do ShooterAttack sem brigar por canal.
class AveEletricaEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _fireRate = 1.4;
  static const double _alcanceTiro = 0.3; // vida curta do projétil = alcance curto

  AveEletricaEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.aveEletrica,
         speed: 32.0, // stats.speed 80 → a mais rápida, mas perseguidora constante
         health: 10,   // frágil: o preço de ignorar o cenário
         dmg: 1,
         bltSpeed: 130, // bicada rápida
         bltImg: 'projeteis/proj2.png',
         bltCor1: CreatureRegistry.aveEletrica.corClara,
         bltCor2: CreatureRegistry.aveEletrica.corEscura,
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
      final distancia = (playerTarget.absolutePosition - absolutePosition).length;
      if (distancia <= 45.0) {
        triggerAttack();
        return;
      }
    }

    updateChaseMovement(dt);
  }

  void _bicar() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao, lifeTime: _alcanceTiro);
  }
}
