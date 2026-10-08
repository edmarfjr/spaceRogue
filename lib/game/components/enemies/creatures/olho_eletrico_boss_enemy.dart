import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/projeteis/feixe_eletrico.dart';
import '../enemy.dart';
import 'olho_eletrico_enemy.dart';

enum _AtaqueOlho { varredura, piscadas, cruz }

/// Zaptron (Zapeye evoluído) como boss. Paira um pouco e solta um ataque, em
/// ciclo, sempre com a linha de mira tracejada antes:
///
/// 1. **Varredura** — o raio gira devagar num arco de 90° pela sala; foge-se
///    do arco ou passa-se por trás dele.
/// 2. **Piscadas** — se teleporta três vezes pela arena, e de cada ponto
///    novo avisa e dispara um raio travado.
/// 3. **Cruz giratória** (só ≤50% de vida) — quatro raios em cruz girando em
///    volta dele; desvia-se girando junto.
class OlhoEletricoBossEnemy extends Enemy {
  static const double _vidaInicial = 220.0;
  static const double _pairar = 2.0;
  static const double _recuperacao = 0.6;

  static const double _avisoVarredura = 0.8;
  static const double _duracaoVarredura = 1.6;
  static const double _arcoVarredura = pi / 2;

  static const int _piscadasPorAtaque = 3;
  static const double _avisoPiscada = 0.5;
  static const double _disparoPiscada = 0.6;

  static const double _avisoCruz = 0.8;
  static const double _duracaoCruz = 3.0;
  static const double _giroCruz = pi / 3; // rad/s

  static const double _danoTique = 2.0;

  final Random _rng = Random();
  bool _faseDois = false;
  int _proximo = 0;

  _AtaqueOlho? _ataque;

  /// 0 = pairando, 1 = avisando, 2 = disparando.
  int _etapa = 0;
  double _timer = _pairar;
  double _recuperando = 0.0;
  int _piscadasRestantes = 0;

  /// Ângulo de referência do ataque atual e quanto tempo ele já rodou —
  /// lidos pelas funções de direção dos feixes, que é como eles giram.
  double _anguloBase = 0.0;
  double _tempoAtaque = 0.0;

  OlhoEletricoBossEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.olhoEletricoEvo,
        speed: 28.0,
        health: _vidaInicial,
        dmg: 2,
        shadowOffset: Vector2(0, 8),
        size: Vector2(48, 48),
        hitboxSize: Vector2(20, 20),
        isPushable: false,
      );

  List<_AtaqueOlho> get _ciclo => _faseDois
      ? const [_AtaqueOlho.varredura, _AtaqueOlho.cruz, _AtaqueOlho.piscadas]
      : const [_AtaqueOlho.varredura, _AtaqueOlho.piscadas];

  double get _anguloAteJogador {
    final v = alvoPosicao - absolutePosition;
    return atan2(v.y, v.x);
  }

  Vector2 _vetor(double angulo) => Vector2(cos(angulo), sin(angulo));

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    if (_recuperando > 0) {
      _recuperando -= dt;
      animateMovement(dt, isMoving: false);
      return;
    }

    _timer -= dt;
    _tempoAtaque += dt;

    if (_ataque == null) {
      // Pairando: chega um pouco mais perto, sem colar.
      final rumo = alvoPosicao - absolutePosition;
      final perto = rumo.length < 70;
      if (!perto && !rumo.isZero()) {
        position += rumo.normalized() * speed * dt;
      }
      animateMovement(dt, isMoving: !perto, horizontalDir: rumo.x);
      if (_timer <= 0) _comecarAtaque();
      return;
    }

    animateMovement(dt, isMoving: false);
    if (_timer > 0) return;

    switch (_ataque!) {
      case _AtaqueOlho.varredura:
        if (_etapa == 1) {
          _dispararVarredura();
        } else {
          _encerrar();
        }
      case _AtaqueOlho.cruz:
        if (_etapa == 1) {
          _dispararCruz();
        } else {
          _encerrar();
        }
      case _AtaqueOlho.piscadas:
        if (_etapa == 1) {
          _dispararPiscada();
        } else if (_piscadasRestantes > 0) {
          _piscarEAvisar();
        } else {
          _encerrar();
        }
    }
  }

  void _comecarAtaque() {
    final ciclo = _ciclo;
    _ataque = ciclo[_proximo % ciclo.length];
    _proximo++;
    _tempoAtaque = 0;
    switch (_ataque!) {
      case _AtaqueOlho.varredura:
        _anguloBase = _anguloAteJogador - _arcoVarredura / 2;
        _avisar([() => _vetor(_anguloBase)], _avisoVarredura);
      case _AtaqueOlho.cruz:
        _anguloBase = _anguloAteJogador;
        _avisar([
          for (var k = 0; k < 4; k++) () => _vetor(_anguloBase + k * pi / 2),
        ], _avisoCruz);
      case _AtaqueOlho.piscadas:
        _piscadasRestantes = _piscadasPorAtaque;
        _piscarEAvisar();
    }
  }

  void _avisar(List<Vector2 Function()> direcoes, double duracao) {
    _etapa = 1;
    _timer = duracao;
    for (final d in direcoes) {
      parent?.add(AvisoDeFeixe(dono: this, direcao: d, vida: duracao));
    }
  }

  void _feixe(Vector2 Function() direcao, double vida) {
    parent?.add(
      FeixeEletrico(
        dono: this,
        direcao: direcao,
        vida: vida,
        danoPorTique: _danoTique,
        tipo: CreatureType.eletrico,
        isEnemy: true,
        origem: creature,
        alcance: 200,
        cor1: CreatureRegistry.olhoEletricoEvo.corClara,
        cor2: CreatureRegistry.olhoEletricoEvo.corEscura,
      ),
    );
  }

  void _dispararVarredura() {
    _etapa = 2;
    _timer = _duracaoVarredura;
    _tempoAtaque = 0;
    _feixe(
      () => _vetor(
        _anguloBase +
            _arcoVarredura * (_tempoAtaque / _duracaoVarredura).clamp(0.0, 1.0),
      ),
      _duracaoVarredura,
    );
  }

  void _dispararCruz() {
    _etapa = 2;
    _timer = _duracaoCruz;
    _tempoAtaque = 0;
    for (var k = 0; k < 4; k++) {
      _feixe(
        () => _vetor(_anguloBase + k * pi / 2 + _giroCruz * _tempoAtaque),
        _duracaoCruz,
      );
    }
  }

  void _piscarEAvisar() {
    _piscadasRestantes--;
    final salto = pontoLivreParaPiscar(this, alvoPosicao, _rng);
    if (salto != null) {
      parent?.add(GhostEffect.fromSprite(visual, duration: 0.3));
      position += salto;
    }
    _anguloBase = _anguloAteJogador;
    final travado = _anguloBase;
    _avisar([() => _vetor(travado)], _avisoPiscada);
  }

  void _dispararPiscada() {
    _etapa = 2;
    _timer = _disparoPiscada;
    final travado = _anguloBase;
    _feixe(() => _vetor(travado), _disparoPiscada);
  }

  void _encerrar() {
    _ataque = null;
    _etapa = 0;
    _timer = _pairar;
    _recuperando = _recuperacao;
  }

  @override
  void death() {
    unlockCreature();
    super.death();
  }
}
