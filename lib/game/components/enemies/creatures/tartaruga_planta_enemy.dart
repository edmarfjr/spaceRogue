import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Tartaruga de Planta como inimigo: lenta, atira semente pesada, e de tempos
/// em tempos **fecha o casco** — para de andar e quase não toma dano. A janela
/// de guarda é o que a define: ensina o jogador a parar de gastar tiro e
/// reposicionar em vez de martelar o mesmo alvo.
class TartarugaPlantaEnemy extends Enemy with WanderMovement, ShooterAttack {
  static const double _fireRate = 2.8;

  // Ciclo da guarda, contado dentro de movimento(dt) — nunca com Future.delayed,
  // que ignoraria pause do jogo e o freeze de transição de sala.
  static const double _tempoAteGuardar = 5.0;
  static const double _duracaoGuarda = 2.2;
  static const double _reducaoGuarda = 0.85;

  double _guardaTimer = 0.0;
  bool _guardando = false;

  TartarugaPlantaEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.tartarugaPlanta,
         speed: 18.0,  // stats.speed 35 → a segunda mais lenta
         health: 35,    // stats.maxHp 20 → tanque do elenco, escalado pro combate
         dmg: 1,
         bltSpeed: 55, // semente pesada e lenta
         bltImg: 'projeteis/proj1.png',
         bltCor1: CreatureRegistry.tartarugaPlanta.corClara,
         bltCor2: CreatureRegistry.tartarugaPlanta.corEscura,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.45);
  }

  @override
  void movimento(double dt) {
    _guardaTimer += dt;

    if (_guardando) {
      // Casco fechado: imóvel e blindada. Nem anda nem atira.
      
      if (_guardaTimer >= _duracaoGuarda) {
        _guardando = false;
        shieldVisualActive = false;
        _guardaTimer = 0.0;
        damageReduction = 0.0;
        visual.scale = Vector2(visual.scale.x.isNegative ? -1.0 : 1.0, 1.0);
      } else {
        // Tell visual: encolhe pra dentro do casco (escala é canal livre aqui,
        // porque nem o MovementAnimator nem o ShooterAttack rodam guardando).
        final flip = visual.scale.x.isNegative ? -1.0 : 1.0;
        visual.scale = Vector2(1.15 * flip, 0.8);
      }
      return;
    }

    if (_guardaTimer >= _tempoAteGuardar) {
      _guardando = true;
      shieldVisualActive = true;
      _guardaTimer = 0.0;
      damageReduction = _reducaoGuarda;
      return;
    }

    // Ataque primeiro com return: `arrastar` escreve visual.scale e brigaria
    // com o pulso do ShooterAttack se rodassem no mesmo frame.
    if (updateAttack(dt, _fireRate, _cuspirSemente)) return;

    if (wantsToShoot) {
      triggerAttack();
      return;
    }

    updateWanderMovement(dt, minPause: 1.0, maxPause: 2.0);
  }

  void _cuspirSemente() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao);
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
