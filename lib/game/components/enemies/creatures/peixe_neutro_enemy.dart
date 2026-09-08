import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Peixe Neutro como inimigo: se debate no chão aos pulos, medindo o jogador
/// — perto, o pulo mira nele; longe, é só flopar sem rumo. A piada visual é
/// literal: peixe fora d'água, mas o dano do pouso é de verdade.
///
/// `moveAnim` null: o JumpMovement escreve visual.scale e visual.position.y.
class PeixeNeutroEnemy extends Enemy with JumpMovement {
  static const double _alcanceBote = 55.0;
  static const int _danoImpacto = 1;
  static const double _empurraoImpacto = 35.0;

  bool _boteEmVoo = false;

  PeixeNeutroEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.peixeNeutro,
        moveAnim: null, // o pulo é a animação
        speed: 0.0, // quem move é o JumpMovement
        health: 20,
        dmg: 1,
        shadowOffset: Vector2(0, 3),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupJumpAnimations(prepTime: 0.35);

    idleDuration = 1.0;
    airDuration = 0.3;
  }

  @override
  void movimento(double dt) {
    final distancia = (playerTarget.absolutePosition - absolutePosition).length;
    final estavaNoAr = jumpState == JumpState.inAir;

    updateJumpMovement(
      dt,
      playerTarget.absolutePosition,
      mode: distancia <= _alcanceBote ? JumpMode.targetPlayer : JumpMode.random,
      jumpDistance: distancia <= _alcanceBote ? _alcanceBote : 22.0,
      jumpHeight: 16.0,
    );

    if (jumpState == JumpState.inAir) _boteEmVoo = true;

    if (estavaNoAr && jumpState != JumpState.inAir && _boteEmVoo) {
      _boteEmVoo = false;
      _impactoAoPousar();
    }
  }

  void _impactoAoPousar() {
    parent?.add(
      ExplosionHitbox(
        position: position.clone(),
        isEnemy: true,
        dmg: _danoImpacto.toDouble(),
        knockback: _empurraoImpacto,
        size: Vector2(28, 28),
        cor1: CreatureRegistry.peixeNeutro.corClara,
        cor2: CreatureRegistry.peixeNeutro.corEscura,
      ),
    );
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
