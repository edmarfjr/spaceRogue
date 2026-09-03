import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Tornado de Fogo como inimigo: forte e rápido, mas o golpe é de perto.
/// Persegue sem parar e, no alcance do soco, para e dá a pancada — um projétil
/// de vida curtíssima, que é o truque que a versão jogável (Soco Flamejante)
/// usa pra ter alcance de corpo a corpo. É o inimigo "não deixe ele encostar".
///
/// `flutuar` é a única animação de movimento que não escreve visual.scale, então
/// é a única que pode conviver com o pulso de ataque do ShooterAttack no mesmo
/// frame sem disputar canal.
class TornadoFogoEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _alcanceSoco = 16.0;
  static const double _fireRate = 1.1;
  static const double _alcanceSegundos = 0.05;

  TornadoFogoEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.tornadoFogo,
         speed: 50.0, // stats.speed 70 → um dos mais rápidos
         health: 20,  // stats.maxHp 10 / defesa 1 → morre rápido se for cercado
         dmg: 1,      // stats.ataque 4 → o soco dói de verdade
         bltSpeed: 100,
         bltImg: 'projeteis/soco.png',
         bltCor1: CreatureRegistry.tornadoFogo.corClara,
         bltCor2: CreatureRegistry.tornadoFogo.corEscura,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.25);
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, _fireRate, _socar)) return;

    final distancia = (playerTarget.absolutePosition - absolutePosition).length;

    // Só soca colado. Longe, o cooldown fica pronto esperando a aproximação.
    if (wantsToShoot && distancia <= _alcanceSoco) {
      triggerAttack();
      return;
    }

    updateChaseMovement(dt);
  }

  void _socar() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao, lifeTime: _alcanceSegundos);
  }
}
