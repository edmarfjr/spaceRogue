import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Peixe Neutro Boss — "Leviatã de Poça": mesmo flopar desesperado da versão
/// comum, pulo maior e mais forte.
///
/// Fase 2 (≤50%): cada pouso deixa uma poça residual no chão, que continua
/// causando dano por um tempo depois do impacto — não basta desviar do
/// pouso, ainda tem que sair da poça.
class PeixeNeutroBossEnemy extends Enemy with JumpMovement {
  static const double _vidaInicial = 110.0;
  static const double _alcanceBote = 80.0;

  static const int _danoImpactoFase1 = 2;
  static const int _danoImpactoFase2 = 3;
  static const double _empurraoImpacto = 45.0;
  static const double _danoPoca = 2.0;
  static const double _duracaoPoca = 2.5;

  bool _boteEmVoo = false;
  bool _faseDois = false;
  bool _morreu = false;

  PeixeNeutroBossEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.peixeNeutro,
        moveAnim: null,
        speed: 0.0,
        health: _vidaInicial,
        dmg: 2,
        shadowOffset: Vector2(0, 5),
        size: Vector2(30, 30),
        hitboxSize: Vector2(20, 16),
        isPushable: false,
      );

  int get _danoImpacto => _faseDois ? _danoImpactoFase2 : _danoImpactoFase1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupJumpAnimations(prepTime: 0.35);

    idleDuration = 1.0;
    airDuration = 0.3;
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    final distancia = (playerTarget.absolutePosition - absolutePosition).length;
    final estavaNoAr = jumpState == JumpState.inAir;

    updateJumpMovement(
      dt,
      playerTarget.absolutePosition,
      mode: distancia <= _alcanceBote ? JumpMode.targetPlayer : JumpMode.random,
      jumpDistance: distancia <= _alcanceBote ? _alcanceBote : 26.0,
      jumpHeight: 20.0,
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
        size: Vector2(38, 38),
        cor1: CreatureRegistry.peixeNeutro.corClara,
        cor2: CreatureRegistry.peixeNeutro.corEscura,
      ),
    );

    if (_faseDois) {
      parent?.add(
        Projectile(
          owner: this,
          position: position.clone(),
          direction: Vector2.zero(),
          isEnemy: true,
          speed: 0,
          kbForce: 0,
          dmg: _danoPoca,
          sprPath: 'projeteis/bolaGrande.png',
          cor1: CreatureRegistry.peixeNeutro.corClara,
          cor2: CreatureRegistry.peixeNeutro.corEscura,
          lifeTime: _duracaoPoca,
          atravessa: 10,
          size: Vector2.all(24.0),
          radius: 10.0,
        ),
      );
    }
  }

  @override
  void death() {
    if (!_morreu) {
      _morreu = true;
      unlockCreature();
    }
    super.death();
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
