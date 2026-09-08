import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Cão Neutro Boss — "Alfa da Matilha": mesma perseguição relentless e
/// mordida de curto alcance da versão comum, maior e mais forte.
///
/// Fase 2 (≤50%): cadência de mordida quase dobra e o dano sobe — a matilha
/// não dá descanso quando fica acuada.
class CaoNeutroBossEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _vidaInicial = 100.0;
  static const double _alcanceMordida = 20.0;
  static const double _fireRateFase1 = 0.9;
  static const double _fireRateFase2 = 0.5;
  static const double _danoFase1 = 3.0;
  static const double _danoFase2 = 4.0;
  static const double _alcanceSegundos = 0.06;

  bool _faseDois = false;
  bool _morreu = false;

  CaoNeutroBossEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.caoNeutro,
        speed: 60.0,
        health: _vidaInicial,
        dmg: 2,
        bltSpeed: 130,
        bltImg: 'projeteis/soco.png',
        bltCor1: CreatureRegistry.caoNeutro.corClara,
        bltCor2: CreatureRegistry.caoNeutro.corEscura,
        size: Vector2(28, 28),
        hitboxSize: Vector2(20, 20),
        isPushable: false,
      );

  double get _fireRate => _faseDois ? _fireRateFase2 : _fireRateFase1;
  double get _dano => _faseDois ? _danoFase2 : _danoFase1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.2);
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

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
    dmg = _dano.toInt();
    shoot(direcao, lifeTime: _alcanceSegundos);
  }

  @override
  void death() {
    if (!_morreu) {
      _morreu = true;
      unlockCreature();
    }
    super.death();
  }
}
