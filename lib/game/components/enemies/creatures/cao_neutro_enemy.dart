import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Cão Neutro como inimigo: persegue sem parar, sem tiro nenhum — a mordida
/// só alcança colado, via projétil de vida curtíssima (mesmo truque do
/// Tornado de Fogo). Sem elemento, sem vantagem/desvantagem: o perigo dele é
/// só não largar do seu rastro.
class CaoNeutroEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _alcanceMordida = 16.0;
  static const double _fireRate = 0.9;
  static const double _alcanceSegundos = 0.05;

  CaoNeutroEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.caoNeutro,
        speed: 55.0, // relentless: um dos mais rápidos perseguidores
        health: 20,
        dmg: 1,
        bltSpeed: 120,
        bltImg: 'projeteis/soco.png',
        bltCor1: CreatureRegistry.caoNeutro.corClara,
        bltCor2: CreatureRegistry.caoNeutro.corEscura,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.2);
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, _fireRate, _morder)) return;

    final distancia = (playerTarget.absolutePosition - absolutePosition).length;
    if (wantsToShoot && distancia <= _alcanceMordida) {
      triggerAttack();
      return;
    }

    updateChaseMovement(dt);
  }

  void _morder() {
    final direcao = (playerTarget.absolutePosition - absolutePosition)
        .normalized();
    shoot(direcao, lifeTime: _alcanceSegundos);
  }
}
