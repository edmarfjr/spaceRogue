import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Gato Neutro como inimigo: fica esperando/reposicionando à toa e, quando o
/// jogador chega perto, dispara um pulo curto e rápido em cima dele — sem o
/// telegrafo longo da Cobra de Água, é bote reflexo, não emboscada calculada.
///
/// `moveAnim` null: o JumpMovement escreve visual.scale e visual.position.y.
class GatoNeutroEnemy extends Enemy with JumpMovement {
  static const double _alcanceBote = 50.0;
  static const int _danoImpacto = 1;
  static const double _empurraoImpacto = 30.0;

  bool _boteEmVoo = false;

  GatoNeutroEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.gatoNeutro,
        moveAnim: null, // o pulo é a animação
        speed: 0.0, // quem move é o JumpMovement
        health: 15, // ágil e frágil
        dmg: 1,
        shadowOffset: Vector2(0, 3),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupJumpAnimations(prepTime: 0.15); // bote reflexo, quase sem aviso

    idleDuration = 0.4; // twitchy: não fica parado muito tempo
    airDuration = 0.25;
  }

  @override
  void movimento(double dt) {
    final distancia = (playerTarget.absolutePosition - absolutePosition).length;
    final estavaNoAr = jumpState == JumpState.inAir;

    updateJumpMovement(
      dt,
      playerTarget.absolutePosition,
      mode: distancia <= _alcanceBote ? JumpMode.targetPlayer : JumpMode.random,
      jumpDistance: distancia <= _alcanceBote ? _alcanceBote : 20.0,
      jumpHeight: 14.0,
    );

    if (jumpState == JumpState.inAir) _boteEmVoo = true;

    if (estavaNoAr && jumpState != JumpState.inAir && _boteEmVoo) {
      _boteEmVoo = false;
      _arranharAoPousar();
    }
  }

  void _arranharAoPousar() {
    parent?.add(
      ExplosionHitbox(
        position: position.clone(),
        isEnemy: true,
        dmg: _danoImpacto.toDouble(),
        knockback: _empurraoImpacto,
        size: Vector2(16, 16),
        cor1: CreatureRegistry.gatoNeutro.corClara,
        cor2: CreatureRegistry.gatoNeutro.corEscura,
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
