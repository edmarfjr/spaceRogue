import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/projeteis/orbit_projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Ave Neutro Boss — "Rainha do Bando": em vez da bicada única da normal,
/// solta um redemoinho de penas GIRANDO ao redor do próprio corpo por um
/// tempo — diferente do anel radial da Ave Elétrica Boss (que voa reto pra
/// fora), aqui o perigo é ficar perto do bicho, não na frente dele.
///
/// Fase 2 (≤50%): mais penas, giro mais rápido.
class AveNeutroBossEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _vidaInicial = 120;
  static const double _alcanceGatilho = 60.0;
  static const double _fireRate = 2.2;

  static const int _numPenasFase1 = 4;
  static const int _numPenasFase2 = 7;
  static const double _velocidadeAngularFase1 = 2.5;
  static const double _velocidadeAngularFase2 = 4.0;
  static const double _raioPenas = 22;
  static const double _duracaoPenas = 2.2;
  static const double _danoFase1 = 2.0;
  static const double _danoFase2 = 3.0;

  bool _faseDois = false;
  bool _morreu = false;

  AveNeutroBossEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.aveNeutro,
        speed: 34.0,
        health: _vidaInicial,
        dmg: 2,
        isAirborne: true,
        shadowOffset: Vector2(0, 10),
        size: Vector2(32, 32),
        hitboxSize: Vector2(18, 22),
        isPushable: false,
      );

  int get _numPenas => _faseDois ? _numPenasFase2 : _numPenasFase1;
  double get _velocidadeAngular =>
      _faseDois ? _velocidadeAngularFase2 : _velocidadeAngularFase1;
  double get _dano => _faseDois ? _danoFase2 : _danoFase1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.25);
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    if (updateAttack(dt, _fireRate, _soltarPenas)) return;

    if (wantsToShoot) {
      final distancia =
          (playerTarget.absolutePosition - absolutePosition).length;
      if (distancia <= _alcanceGatilho) {
        triggerAttack();
        return;
      }
    }

    updateChaseMovement(dt);
  }

  void _soltarPenas() {
    for (int i = 0; i < _numPenas; i++) {
      final angulo = 2 * pi * i / _numPenas;
      parent?.add(
        OrbitProjectile(
          owner: this,
          anguloAtual: angulo,
          raio: _raioPenas,
          velocidadeAngular: _velocidadeAngular,
          dmg: _dano,
          isEnemy: true,
          sprPath: 'projeteis/proj2.png',
          cor1: CreatureRegistry.aveNeutro.corClara,
          cor2: CreatureRegistry.aveNeutro.corEscura,
          lifeTime: _duracaoPenas,
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
}
