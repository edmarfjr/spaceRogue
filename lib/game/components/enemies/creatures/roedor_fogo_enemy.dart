import 'dart:math';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Roedor de Fogo como inimigo: rápido, vaga sem parar e dispara um leque de
/// 3 brasas — o espelho da Rajada de Brasa do jogador. Alto dano por rajada,
/// mas morre num golpe sólido. Pressão de "sai do cone".
class RoedorFogoEnemy extends Enemy with WanderMovement, ShooterAttack {
  static const double _fireRate = 2.2;
  static const double _anguloLequeGraus = 20;

  RoedorFogoEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.roedorFogo,
         speed: 45.0,   // stats.speed 70 → rápido, mas jogável de encarar
         health: 15,
         dmg: 1,
         bltSpeed: 90,
         bltImg: 'projeteis/fogo2.png',
         bltCor1: CreatureRegistry.roedorFogo.corClara,
         bltCor2: CreatureRegistry.roedorFogo.corEscura,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.35);
  }

  @override
  void movimento(double dt) {
    // Ataque primeiro, com return: `caminhada` escreve visual.scale e brigaria
    // com o pulso do ShooterAttack se os dois rodassem no mesmo frame.
    if (updateAttack(dt, _fireRate, _dispararLeque)) return;

    if (wantsToShoot) {
      final distancia = (playerTarget.absolutePosition - absolutePosition).length;
      if (distancia <= 80.0) {
        triggerAttack();
        return;
      }
    }

    updateWanderMovement(dt, minPause: 0.1, maxPause: 0.4);
  }

  void _dispararLeque() {
    final base = (playerTarget.absolutePosition - absolutePosition).normalized();
    final anguloRad = _anguloLequeGraus * pi / 180;

    for (final offset in [-anguloRad, 0.0, anguloRad]) {
      shoot(base.clone()..rotate(offset),lifeTime: 0.5);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is WallBarrier || other is Obstacle) {
      if (!isPhysicsCollision(other)) return;
      cancelWander();
    }
  }
}
