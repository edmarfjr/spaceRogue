import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Gato Neutro Boss — "Sombra de Nove Vidas": mesmo bote reflexo da versão
/// comum, maior e mais forte.
///
/// Fase 2 (≤50%): encadeia até 3 botes seguidos (sem voltar a esperar) em vez
/// de um só — mesmo truque do bote duplo da Cobra de Água, um degrau acima.
class GatoNeutroBossEnemy extends Enemy with JumpMovement {
  static const double _vidaInicial = 90.0;
  static const double _alcanceBote = 65.0;

  static const int _danoImpactoFase1 = 2;
  static const int _danoImpactoFase2 = 3;
  static const double _empurraoImpacto = 40.0;

  static const int _botesPorCicloFase1 = 1;
  static const int _botesPorCicloFase2 = 3;

  bool _boteEmVoo = false;
  bool _faseDois = false;
  bool _morreu = false;
  int _botesFeitos = 0;

  GatoNeutroBossEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.gatoNeutro,
        moveAnim: null,
        speed: 0.0,
        health: _vidaInicial,
        dmg: 2,
        shadowOffset: Vector2(0, 5),
        size: Vector2(26, 26),
        hitboxSize: Vector2(16, 18),
        isPushable: false,
      );

  int get _danoImpacto => _faseDois ? _danoImpactoFase2 : _danoImpactoFase1;
  int get _botesPorCiclo =>
      _faseDois ? _botesPorCicloFase2 : _botesPorCicloFase1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupJumpAnimations(prepTime: 0.15);

    idleDuration = 0.4;
    airDuration = 0.25;
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
      jumpDistance: distancia <= _alcanceBote ? _alcanceBote : 24.0,
      jumpHeight: 16.0,
    );

    if (jumpState == JumpState.inAir) _boteEmVoo = true;

    if (estavaNoAr && jumpState != JumpState.inAir && _boteEmVoo) {
      _boteEmVoo = false;
      _arranharAoPousar();
      _botesFeitos++;

      if (_botesFeitos < _botesPorCiclo) {
        jumpState = JumpState.preparing;
        jumpTimer = 0.0;
        spawnAlerta();
      } else {
        _botesFeitos = 0;
      }
    }
  }

  void _arranharAoPousar() {
    parent?.add(
      ExplosionHitbox(
        position: position.clone(),
        isEnemy: true,
        dmg: _danoImpacto.toDouble(),
        knockback: _empurraoImpacto,
        size: Vector2(32, 32),
        cor1: CreatureRegistry.gatoNeutro.corClara,
        cor2: CreatureRegistry.gatoNeutro.corEscura,
      ),
    );
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
