import 'dart:math';
import 'dart:ui' show Offset;

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/projeteis/feixe_eletrico.dart';
import '../enemy.dart';

/// Ponto livre no chão da sala do inimigo [e], a uma distância entre
/// [minimo] e [maximo] de [centro] — destino do teleporte do Zapeye inimigo e
/// do boss. Sorteia algumas direções e devolve a primeira em que a hitbox
/// dos pés cabe sem encostar em parede, pedra ou buraco, ou `null`.
///
/// Mesma regra do teleporte do jogador (`Player.deslocamentoDoPiscar`): o
/// destino tem que estar DENTRO da sala atual.
Vector2? pontoLivreParaPiscar(
  Enemy e,
  Vector2 centro,
  Random rng, {
  double minimo = 56,
  double maximo = 88,
}) {
  final sala = e.currentRoom;
  if (sala == null) return null;
  final area = sala.areaInterna;
  final solidos = [
    for (final c in sala.children.whereType<PositionComponent>())
      if (barraMovimento(c, isAirborne: false)) c.toAbsoluteRect(),
  ];
  final pes = e.physicsHitbox.toAbsoluteRect();
  for (var tentativa = 0; tentativa < 16; tentativa++) {
    final angulo = rng.nextDouble() * 2 * pi;
    final dist = minimo + rng.nextDouble() * (maximo - minimo);
    final destino = centro + Vector2(cos(angulo), sin(angulo)) * dist;
    final desloc = destino - e.absolutePosition;
    final r = pes.shift(Offset(desloc.x, desloc.y));
    if (!area.contains(r.topLeft) || !area.contains(r.bottomRight)) continue;
    if (solidos.any((s) => s.overlaps(r))) continue;
    return desloc;
  }
  return null;
}

/// Zapeye como inimigo: olho flutuante que MANTÉM distância. Avisa com uma
/// linha de mira tracejada e então dispara o raio TRAVADO naquela direção —
/// o raio não segue o jogador, então dá pra sair de lado. Quando o jogador
/// chega perto, pisca pra longe: persegui-lo não resolve, só posicionamento.
class OlhoEletricoEnemy extends Enemy {
  static const double _distanciaIdeal = 80.0;
  static const double _avisoDuracao = 0.6;
  static const double _disparoDuracao = 0.8;
  static const double _recarga = 1.4;
  static const double _perigoPerto = 36.0;
  static const double _recargaPiscar = 3.0;

  final Random _rng = Random();
  double _estadoTimer = _recarga;
  bool _avisando = false;
  bool _disparando = false;
  double _piscarTimer = 0.0;
  Vector2 _mira = Vector2(0, 1);

  OlhoEletricoEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.olhoEletrico,
        speed: 30.0,
        health: 14,
        dmg: 1,
        shadowOffset: Vector2(0, 5),
      );

  @override
  void movimento(double dt) {
    if (_piscarTimer > 0) _piscarTimer -= dt;
    _estadoTimer -= dt;

    final rumo = alvoPosicao - absolutePosition;
    final distancia = rumo.length;

    if (_disparando) {
      animateMovement(dt, isMoving: false);
      if (_estadoTimer <= 0) {
        _disparando = false;
        _estadoTimer = _recarga;
      }
      return;
    }

    if (_avisando) {
      animateMovement(dt, isMoving: false);
      if (_estadoTimer <= 0) _disparar();
      return;
    }

    if (distancia < _perigoPerto && _piscarTimer <= 0) {
      _piscarParaLonge();
      return;
    }

    if (_estadoTimer <= 0) {
      _avisar(rumo);
      return;
    }

    // Fica orbitando a distância ideal: afasta se o jogador chegou perto,
    // aproxima se ficou longe demais.
    if (distancia > 0) {
      final sentido = distancia < _distanciaIdeal - 12
          ? -1.0
          : distancia > _distanciaIdeal + 24
          ? 1.0
          : 0.0;
      if (sentido != 0) {
        position += rumo.normalized() * sentido * speed * dt;
      }
      animateMovement(dt, isMoving: sentido != 0, horizontalDir: rumo.x);
    }
  }

  void _avisar(Vector2 rumo) {
    _mira = rumo.isZero() ? Vector2(0, 1) : rumo.normalized();
    _avisando = true;
    _estadoTimer = _avisoDuracao;
    final travada = _mira.clone();
    parent?.add(
      AvisoDeFeixe(dono: this, direcao: () => travada, vida: _avisoDuracao),
    );
  }

  void _disparar() {
    _avisando = false;
    _disparando = true;
    _estadoTimer = _disparoDuracao;
    final travada = _mira.clone();
    parent?.add(
      FeixeEletrico(
        dono: this,
        direcao: () => travada,
        vida: _disparoDuracao,
        danoPorTique: 1,
        tipo: CreatureType.eletrico,
        isEnemy: true,
        origem: creature,
        cor1: CreatureRegistry.olhoEletrico.corClara,
        cor2: CreatureRegistry.olhoEletrico.corEscura,
      ),
    );
  }

  void _piscarParaLonge() {
    _piscarTimer = _recargaPiscar;
    final salto = pontoLivreParaPiscar(this, alvoPosicao, _rng);
    if (salto == null) return;
    parent?.add(GhostEffect.fromSprite(visual, duration: 0.3));
    position += salto;
  }
}
