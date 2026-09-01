import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Grilo Elétrico Boss: mesmo padrão evasivo da normal — pula pra longe do
/// jogador (`JumpMode.random`, nunca mira), solta faísca só com os pés no
/// chão. O perigo nunca é o corpo dele, é não deixar você encostar.
///
/// Fase 2 (≤50%): larga nós elétricos estáticos ao longo do arco, ainda no
/// ar — diferente da poça do Slime (5s, terreno acumulado), o nó dura só
/// 1.2s: é esquiva em tempo real do trajeto do pulo, não negação de área.
class GriloEletricoBossEnemy extends Enemy with JumpMovement, ShooterAttack {
  static const double _vidaInicial = 150.0; // 4x a normal (16)
  static const double _fireRate = 1.6;
  static const double _danoFaiscaFase2 = 4.0;
  static const double _danoNo = 3.0;

  static const double _jumpDistancia = 40.0;
  static const double _jumpAltura = 20.0;
  static const double _noIntervalo = 0.15;
  static const double _noDuracao = 1.2;

  bool _faseDois = false;
  double _noTimer = 0.0;

  GriloEletricoBossEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.griloEletrico,
         moveAnim: null, // o pulo é a animação
         speed: 0.0,     // quem move é o JumpMovement
         health: _vidaInicial,
         dmg: 3, // dano da faísca na fase 1 — fase 2 escala pra _danoFaiscaFase2
         bltSpeed: 130,
         bltImg: 'projeteis/raio.png',
         bltCor1: CreatureRegistry.griloEletrico.corClara,
         bltCor2: CreatureRegistry.griloEletrico.corEscura,
         shadowOffset: Vector2(0, 6),
         size: Vector2(32, 32),        // dobro do padrão (16x16)
         hitboxSize: Vector2(16, 20),  // dobro do hitbox normal (8, 10)
         isPushable: false,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupJumpAnimations(prepTime: 0.15);
    setupAttackAnimation(duration: 0.2);

    idleDuration = 0.25;
    airDuration = 0.4;
  }

  @override
  void movimento(double dt) {
    // shoot() usa o campo `dmg` herdado direto — sem getter por chamada,
    // então a escalada de fase é uma atribuição única na virada.
    if (!_faseDois && health <= _vidaInicial / 2) {
      _faseDois = true;
      dmg = _danoFaiscaFase2.toInt();
    }

    // Fase 2: enquanto no ar, larga nós ao longo do trajeto do pulo.
    if (_faseDois && jumpState == JumpState.inAir) {
      _noTimer += dt;
      if (_noTimer >= _noIntervalo) {
        _noTimer = 0.0;
        _soltarNo();
      }
    } else {
      _noTimer = 0.0;
    }

    if (updateAttack(dt, _fireRate, _faisca)) return;

    // Só atira com os pés no chão — nunca no meio do pulo.
    if (wantsToShoot && jumpState == JumpState.idle) {
      triggerAttack();
      return;
    }

    // JumpMode.random sempre: ele foge do jogador, não mira nele.
    updateJumpMovement(
      dt,
      playerTarget.absolutePosition,
      mode: JumpMode.random,
      jumpDistance: _jumpDistancia,
      jumpHeight: _jumpAltura,
    );
  }

  void _faisca() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao);
  }

  void _soltarNo() {
    parent?.add(Projectile(
      position: position.clone(),
      direction: Vector2.zero(),
      isEnemy: true, // sem isso o nó machuca inimigos em vez do jogador
      speed: 0,
      kbForce: 0,
      dmg: _danoNo,
      sprPath: 'projeteis/raio.png',
      cor1: CreatureRegistry.griloEletrico.corClara,
      cor2: CreatureRegistry.griloEletrico.corEscura,
      lifeTime: _noDuracao,
      atravessa: 10,
      atravessaObstaculos: true,
      size: Vector2.all(12),
      radius: 6,
    ));
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
      cancelJump();
    }
  }
}
