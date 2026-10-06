import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color;
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esguicho_de_tinta.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/projeteis/golpe_de_tentaculo.dart';
import '../enemy.dart';

/// Calamarin como inimigo: persegue até o alcance do tentáculo, AVISA
/// (exclamação, parado) e varre um arco à frente — depois fica um instante
/// exposto. A janela entre o aviso e o golpe é o que torna o corpo a corpo
/// dele legível: dá pra recuar ou atacar primeiro.
///
/// Quando apanha, foge: dispara pra longe do jogador soltando uma nuvem de
/// tinta que CEGA o jogador. Insistir colado nele custa a visão.
class SereiaAguaEnemy extends Enemy {
  static const double _alcanceGolpe = 22.0;
  static const double _aviso = 0.4;
  static const double _recuperacao = 0.6;
  static const double _danoGolpe = 2.0;

  static const double _fugaRecarga = 4.0;
  static const double _fugaDuracao = 0.2;
  static const double _fugaVelocidade = 160.0;

  double _avisoTimer = 0.0;
  double _recuperacaoTimer = 0.0;
  double _fugaTimer = 0.0;
  double _fugaRecargaTimer = 0.0;
  Vector2 _fugaDirecao = Vector2.zero();
  double _sentido = 1.0;

  SereiaAguaEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.sereiaAgua,
        speed: 28.0,
        health: 18,
        dmg: 1,
        shadowOffset: Vector2(0, 4),
      );

  Vector2 get _paraJogador {
    final v = alvoPosicao - absolutePosition;
    return v.length == 0 ? Vector2(0, 1) : v.normalized();
  }

  @override
  void movimento(double dt) {
    if (_fugaRecargaTimer > 0) _fugaRecargaTimer -= dt;

    if (_fugaTimer > 0) {
      _fugaTimer -= dt;
      position += _fugaDirecao * _fugaVelocidade * dt;
      return;
    }

    if (_recuperacaoTimer > 0) {
      _recuperacaoTimer -= dt;
      animateMovement(dt, isMoving: false);
      return;
    }

    if (_avisoTimer > 0) {
      _avisoTimer -= dt;
      animateMovement(dt, isMoving: false);
      if (_avisoTimer <= 0) {
        _golpear();
        _recuperacaoTimer = _recuperacao;
      }
      return;
    }

    final distancia = (alvoPosicao - absolutePosition).length;
    // Cego também golpeia — no ponto onde viu o jogador por último (ver
    // `Enemy.alvoPosicao`), e às cegas o golpe acerta outros inimigos.
    if (distancia <= _alcanceGolpe) {
      _avisoTimer = _aviso;
      spawnAlerta(duracao: _aviso);
      return;
    }

    updateChaseMovement(dt);
  }

  void _golpear() {
    _sentido = -_sentido;
    parent?.add(
      GolpeDeTentaculo(
        dono: this,
        direcao: _paraJogador,
        arco: 2 * pi / 3,
        sentido: _sentido,
        duracao: 0.2,
        alcance: _alcanceGolpe + 4,
        dano: _danoGolpe,
        tipo: CreatureType.agua,
        isEnemy: true,
        origem: creature,
        cor1: CreatureRegistry.sereiaAgua.corClara,
        cor2: CreatureRegistry.sereiaAgua.corEscura,
      ),
    );
  }

  @override
  void takeDamage(
    double amount, {
    Color corTxt = Palette.amarelo,
    CreatureType tipoAtacante = CreatureType.neutro,
    bool doJogador = true,
    bool revela = true,
  }) {
    super.takeDamage(
      amount,
      corTxt: corTxt,
      tipoAtacante: tipoAtacante,
      doJogador: doJogador,
      revela: revela,
    );
    if (health <= 0 || _fugaRecargaTimer > 0 || amount <= 0) return;
    _fugir();
  }

  void _fugir() {
    _fugaRecargaTimer = _fugaRecarga;
    _fugaTimer = _fugaDuracao;
    _avisoTimer = 0;
    _recuperacaoTimer = 0;
    _fugaDirecao = -_paraJogador;

    parent?.add(
      EsguichoDeTinta.nuvem(
        dono: this,
        posicao: position.clone(),
        cegueira: 1.0,
        vida: 2.5,
        lado: 24,
        isEnemy: true,
      ),
    );
    GhostEffect.spawnTrail(
      visual: visual,
      add: (g) => parent?.add(g),
      overDuration: _fugaDuracao,
    );
  }
}
