import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Ave de Eletricidade Boss — "Garibirb": em vez da bicada única da normal,
/// solta um anel radial de bicadas ao redor do próprio corpo. Continua voando
/// e atravessando pedra/buraco — os projéteis herdam isso, então esconder
/// atrás do cenário não protege de nenhum dos dois vetores.
///
/// Fase 2 (≤50%): um segundo anel sai logo atrás do primeiro, girado meio
/// passo — fecha os buracos entre os projéteis do primeiro anel.
class AveEletricaBossEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _vidaInicial = 120;
  static const double _alcanceGatilho = 70.0; // maior que a normal (45): AoE ameaça de mais longe
  static const double _fireRate = 1.8;
  static const int _numProjeteis = 6;
  static const double _anelSpeed = 100.0;
  static const double _anelLifeTime = 0.6;
  static const double _atrasoSegundoAnel = 0.15;
  static const double _danoFase1 = 3.0;
  static const double _danoFase2 = 4.0;

  bool _faseDois = false;
  bool _segundoAnelPendente = false;
  double _segundoAnelTimer = 0.0;

  AveEletricaBossEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.aveEletrica,
         speed: 34.0,
         health: _vidaInicial,
         dmg: 3,
         isAirborne: true, // passa por cima de pedra e buraco, igual à normal
         shadowOffset: Vector2(0, 10),
         size: Vector2(32, 32),        // dobro do padrão (16x16)
         hitboxSize: Vector2(18, 22),  // dobro do hitbox normal (9, 11)
         isPushable: false,
       );

  double get _dano => _faseDois ? _danoFase2 : _danoFase1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.25);
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    // Segundo anel da fase 2: sai logo depois do primeiro, ainda travado.
    if (_segundoAnelPendente) {
      _segundoAnelTimer -= dt;
      animateMovement(dt, isMoving: false);
      if (_segundoAnelTimer <= 0) {
        _segundoAnelPendente = false;
        _dispararAnel(offsetGraus: 30);
      }
      return;
    }

    if (updateAttack(dt, _fireRate, _aoConcluirAtaque)) return;

    if (wantsToShoot) {
      final distancia = (playerTarget.absolutePosition - absolutePosition).length;
      if (distancia <= _alcanceGatilho) {
        triggerAttack();
        return;
      }
    }

    updateChaseMovement(dt);
  }

  void _aoConcluirAtaque() {
    _dispararAnel(offsetGraus: 0);
    if (_faseDois) {
      _segundoAnelPendente = true;
      _segundoAnelTimer = _atrasoSegundoAnel;
    }
  }

  void _dispararAnel({required double offsetGraus}) {
    final anguloBase = offsetGraus * pi / 180;
    for (int i = 0; i < _numProjeteis; i++) {
      final angulo = anguloBase + (2 * pi * i / _numProjeteis);
      final direcao = Vector2(cos(angulo), sin(angulo));
      parent?.add(Projectile(
        position: position.clone(),
        direction: direcao,
        isEnemy: true, // sem isso o anel machuca inimigos em vez do jogador
        speed: _anelSpeed,
        dmg: _dano,
        sprPath: 'projeteis/proj2.png',
        cor1: CreatureRegistry.aveEletrica.corClara,
        cor2: CreatureRegistry.aveEletrica.corEscura,
        lifeTime: _anelLifeTime,
        atravessaObstaculos: true, // voa: ignora pedra e buraco, igual à normal
      ));
    }
  }

  @override
  void death() {
    CreatureProgress.instance.unlock('ave_eletrica');
    super.death();
  }
}
