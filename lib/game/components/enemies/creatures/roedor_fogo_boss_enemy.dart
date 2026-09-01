import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Roedor de Fogo Boss: a normal dispara um leque de 3 brasas. Este dispara
/// um leque de 5, mais largo — e cada brasa estilhaça em faíscas ao se
/// apagar (`fragmentos`), então quem só desvia da brasa em si ainda leva o
/// estilhaço.
///
/// Fase 2 (≤50%): o leque abre mais e recarrega mais rápido — mais projéteis
/// no ar ao mesmo tempo, não só mais dano por acerto.
class RoedorFogoBossEnemy extends Enemy with WanderMovement, ShooterAttack {
  static const double _vidaInicial = 200.0; // 4x a normal (30)
  static const double _alcanceGatilho = 90.0;

  static const double _fireRateFase1 = 2.4;
  static const double _fireRateFase2 = 1.8;
  static const double _anguloLequeGrausFase1 = 18.0;
  static const double _anguloLequeGrausFase2 = 22.0;
  static const double _danoFase1 = 4.0;
  static const double _danoFase2 = 5.0;

  static const int _fragmentosPorBrasa = 2;

  bool _faseDois = false;

  RoedorFogoBossEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.roedorFogo,
         speed: 38.0,
         health: _vidaInicial,
         dmg: 4,
         size: Vector2(32, 32),        // dobro do padrão (16x16)
         hitboxSize: Vector2(16, 20),  // dobro do hitbox normal (8, 10)
         isPushable: false,
       );

  double get _fireRate => _faseDois ? _fireRateFase2 : _fireRateFase1;
  double get _anguloLequeGraus => _faseDois ? _anguloLequeGrausFase2 : _anguloLequeGrausFase1;
  double get _dano => _faseDois ? _danoFase2 : _danoFase1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.35);
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    if (updateAttack(dt, _fireRate, _dispararLeque)) return;

    if (wantsToShoot) {
      final distancia = (playerTarget.absolutePosition - absolutePosition).length;
      if (distancia <= _alcanceGatilho) {
        triggerAttack();
        return;
      }
    }

    updateWanderMovement(dt, minPause: 0.1, maxPause: 0.4);
  }

  void _dispararLeque() {
    final base = (playerTarget.absolutePosition - absolutePosition).normalized();
    final passoRad = _anguloLequeGraus * pi / 180;

    // Leque de 5: dois passos pra cada lado do centro, mais largo que o
    // leque de 3 da normal.
    for (final offset in [-2 * passoRad, -passoRad, 0.0, passoRad, 2 * passoRad]) {
      parent?.add(Projectile(
        position: position.clone(),
        direction: base.clone()..rotate(offset),
        isEnemy: true, // sem isso a brasa machuca inimigos em vez do jogador
        speed: 90,
        dmg: _dano,
        sprPath: 'projeteis/fogo2.png',
        cor1: CreatureRegistry.roedorFogo.corClara,
        cor2: CreatureRegistry.roedorFogo.corEscura,
        lifeTime: 0.5,
        fragmentos: _fragmentosPorBrasa,
      ));
    }
  }

  @override
  void death() {
    unlockCreature();
    super.death();
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
