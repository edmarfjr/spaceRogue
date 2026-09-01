import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Leão Elétrico Boss: fase 1 é a normal (persegue, estoca à distância).
/// Fase 2 (≤50%) é a transformação — abandona a estocada e passa a saltar
/// em cima do jogador, com uma queda elétrica em área ao pousar. A forma
/// jogável nunca vê essa fase; é o que a diferencia do inimigo comum sem
/// precisar de uma terceira habilidade.
class LeaoEletricoBossEnemy extends Enemy with ChaseMovement, ShooterAttack, JumpMovement {
  static const double _vidaInicial = 250.0; // 4x a normal (26)
  static const double _fireRate = 1.4;
  static const double _alcanceTiro = 60.0;
  static const double _danoQueda = 6.0;
  static const double _empurraoQueda = 80.0;

  bool _faseDois = false;
  bool _emVoo = false;

  LeaoEletricoBossEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.leaoEletrico,
         speed: 44.0,
         health: _vidaInicial,
         dmg: 4,
         bltSpeed: 150,
         bltImg: 'projeteis/raio.png',
         bltCor1: CreatureRegistry.leaoEletrico.corClara,
         bltCor2: CreatureRegistry.leaoEletrico.corEscura,
         shadowOffset: Vector2(0, 8),
         size: Vector2(32, 32),        // dobro do padrão (16x16)
         hitboxSize: Vector2(22, 30),  // dobro do hitbox normal (11, 15)
         isPushable: false,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.25, telegraph: 0.35);
    setupJumpAnimations(prepTime: 0.4);
    idleDuration = 0.9;
    airDuration = 0.5;
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    if (_faseDois) {
      _movimentoFaseDois(dt);
      return;
    }

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

  void _movimentoFaseDois(double dt) {
    updateJumpMovement(
      dt,
      playerTarget.absolutePosition,
      mode: JumpMode.targetPlayer,
      jumpDistance: 50.0,
      jumpHeight: 30.0,
    );

    if (jumpState == JumpState.inAir) _emVoo = true;

    if (jumpState != JumpState.inAir && _emVoo) {
      _emVoo = false;
      _quedaEletrica();
    }
  }

  void _estocar() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao, lifeTime: 1.2);
  }

  void _quedaEletrica() {
    parent?.add(ExplosionHitbox(
      position: position.clone(),
      isEnemy: true,
      dmg: _danoQueda,
      knockback: _empurraoQueda,
      size: Vector2(40, 40),
      cor1: CreatureRegistry.leaoEletrico.corClara,
      cor2: CreatureRegistry.leaoEletrico.corEscura,
    ));
  }

  @override
  void death() {
    CreatureProgress.instance.unlock('leao_eletrico');
    super.death();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_faseDois && (other is WallBarrier || other is Obstacle)) {
      if (!isPhysicsCollision(other)) return;
      cancelJump();
    }
  }
}
