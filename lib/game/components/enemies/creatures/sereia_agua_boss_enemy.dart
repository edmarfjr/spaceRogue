import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esguicho_de_tinta.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import 'package:creatures_rogue/game/components/projeteis/golpe_de_tentaculo.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
import '../enemy.dart';

enum _Ataque { redemoinho, cortina, tentaculosDoChao }

/// Kalamarok (Calamarin evoluído) como boss. Persegue um pouco e então solta
/// um dos ataques, em ciclo, todos avisados antes:
///
/// 1. **Redemoinho** — aviso longo, depois o tentáculo gira 360° com alcance
///    grande. A resposta é sair do raio.
/// 2. **Cortina de Tinta invertida** — atravessa a arena deixando um rastro
///    de nuvens que cegam e ENGOLEM os tiros do jogador. É o espelho da
///    habilidade dele: obriga a se reposicionar pra voltar a acertar.
/// 3. **Tentáculos do chão** (só ≤50% de vida) — círculos de aviso no chão
///    em volta do jogador; depois de [_avisoChao] brota um golpe em cada um.
class SereiaAguaBossEnemy extends Enemy {
  static const double _vidaInicial = 220.0;

  static const double _perseguicao = 2.2;

  static const double _avisoRedemoinho = 0.8;
  static const double _alcanceRedemoinho = 44.0;
  static const double _danoRedemoinho = 3.0;

  static const double _avisoCortina = 0.5;
  static const double _cortinaDuracao = 0.5;
  static const double _cortinaVelocidade = 180.0;
  static const double _cortinaIntervaloNuvem = 0.1;

  static const int _tentaculosNoChao = 4;
  static const double _avisoChao = 0.8;
  static const double _danoChao = 2.0;

  static const double _recuperacao = 0.6;

  bool _faseDois = false;
  _Ataque? _ataque;
  int _proximo = 0;

  double _perseguindoTimer = _perseguicao;
  double _avisoTimer = 0.0;
  double _recuperacaoTimer = 0.0;

  bool _emCortina = false;
  double _cortinaTimer = 0.0;
  double _nuvemTimer = 0.0;
  Vector2 _cortinaDirecao = Vector2.zero();

  SereiaAguaBossEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.sereiaAguaEvo,
        speed: 32.0,
        health: _vidaInicial,
        dmg: 2,
        shadowOffset: Vector2(0, 8),
        size: Vector2(48, 48),
        hitboxSize: Vector2(20, 20),
        isPushable: false,
      );

  List<_Ataque> get _ciclo => _faseDois
      ? const [_Ataque.redemoinho, _Ataque.tentaculosDoChao, _Ataque.cortina]
      : const [_Ataque.redemoinho, _Ataque.cortina];

  Vector2 get _paraJogador {
    final v = playerTarget.absolutePosition - absolutePosition;
    return v.length == 0 ? Vector2(0, 1) : v.normalized();
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    if (_emCortina) {
      _atualizarCortina(dt);
      return;
    }

    if (_recuperacaoTimer > 0) {
      _recuperacaoTimer -= dt;
      animateMovement(dt, isMoving: false);
      return;
    }

    if (_ataque != null) {
      _avisoTimer -= dt;
      animateMovement(dt, isMoving: false);
      if (_avisoTimer <= 0) _soltarAtaque();
      return;
    }

    _perseguindoTimer -= dt;
    if (_perseguindoTimer <= 0) {
      _armarProximoAtaque();
      return;
    }
    updateChaseMovement(dt);
  }

  void _armarProximoAtaque() {
    final ciclo = _ciclo;
    final ataque = ciclo[_proximo % ciclo.length];
    _proximo++;
    _ataque = ataque;
    _avisoTimer = switch (ataque) {
      _Ataque.redemoinho => _avisoRedemoinho,
      _Ataque.cortina => _avisoCortina,
      // O aviso deste mora nos círculos do chão; o boss só para um instante.
      _Ataque.tentaculosDoChao => 0.3,
    };
    spawnAlerta(duracao: _avisoTimer);
  }

  void _soltarAtaque() {
    final ataque = _ataque!;
    _ataque = null;
    _perseguindoTimer = _perseguicao;

    switch (ataque) {
      case _Ataque.redemoinho:
        parent?.add(
          GolpeDeTentaculo(
            dono: this,
            direcao: _paraJogador,
            arco: 2 * pi,
            duracao: 0.4,
            alcance: _alcanceRedemoinho,
            dano: _danoRedemoinho,
            empurrao: 60,
            tipo: CreatureType.agua,
            isEnemy: true,
            origem: creature,
            cor1: CreatureRegistry.sereiaAguaEvo.corClara,
            cor2: CreatureRegistry.sereiaAguaEvo.corEscura,
          ),
        );
        _recuperacaoTimer = _recuperacao;
      case _Ataque.cortina:
        _emCortina = true;
        _cortinaTimer = _cortinaDuracao;
        _nuvemTimer = 0.0;
        _cortinaDirecao = _paraJogador;
        GhostEffect.spawnTrail(
          visual: visual,
          add: (g) => parent?.add(g),
          overDuration: _cortinaDuracao,
        );
      case _Ataque.tentaculosDoChao:
        _plantarTentaculos();
        _recuperacaoTimer = _recuperacao;
    }
  }

  void _atualizarCortina(double dt) {
    _cortinaTimer -= dt;
    _nuvemTimer -= dt;
    position += _cortinaDirecao * _cortinaVelocidade * dt;

    if (_nuvemTimer <= 0) {
      _nuvemTimer = _cortinaIntervaloNuvem;
      parent?.add(
        EsguichoDeTinta.nuvem(
          dono: this,
          posicao: position.clone(),
          // Curta de propósito: nuvens em sequência renovam a cegueira, e
          // somadas ao bloqueio de tiro uma cegueira longa vira tela preta.
          cegueira: 0.6,
          vida: 3.5,
          lado: 24,
          isEnemy: true,
          bloqueiaTiro: true,
        ),
      );
    }

    if (_cortinaTimer <= 0) _encerrarCortina();
  }

  void _encerrarCortina() {
    _emCortina = false;
    _recuperacaoTimer = _recuperacao;
  }

  void _plantarTentaculos() {
    final rng = Random();
    final alvo = playerTarget.position.clone();
    for (int i = 0; i < _tentaculosNoChao; i++) {
      // O primeiro cai exatamente onde o jogador está; os outros em volta,
      // pra fechar as rotas de fuga mais óbvias.
      final ponto = i == 0
          ? alvo.clone()
          : alvo +
                (Vector2(1, 0)..rotate(rng.nextDouble() * 2 * pi)) *
                    (16 + rng.nextDouble() * 24);
      parent?.add(_AvisoTentaculo(boss: this, position: ponto));
    }
  }

  void _brotarTentaculo(Vector2 ponto) {
    parent?.add(
      ExplosionHitbox(
        position: ponto,
        isEnemy: true,
        origem: creature,
        dmg: _danoChao,
        knockback: 40,
        size: Vector2(20, 20),
        tipo: CreatureType.agua,
        cor1: CreatureRegistry.sereiaAguaEvo.corClara,
        cor2: CreatureRegistry.sereiaAguaEvo.corEscura,
      ),
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // A travessia para na parede em vez de raspar nela até o fim do tempo.
    if (_emCortina && (other is WallBarrier || other is Obstacle)) {
      if (!isPhysicsCollision(other)) return;
      _encerrarCortina();
    }
  }

  @override
  void death() {
    unlockCreature();
    super.death();
  }
}

/// Círculo piscando no chão que avisa onde um tentáculo vai brotar. Ao fim
/// do aviso, pede ao boss o golpe — e não brota nada se o boss já morreu,
/// senão um tentáculo pendente acertaria o jogador depois da vitória.
class _AvisoTentaculo extends PositionComponent {
  final SereiaAguaBossEnemy boss;
  double _tempo = 0.0;

  final Paint _tinta = Paint()
    ..color = Palette.vermelho
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  _AvisoTentaculo({required this.boss, required Vector2 position})
    : super(position: position, anchor: Anchor.center, size: Vector2.all(20)) {
    priority = ySortPriority(position.y) - 1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    if (_tempo < SereiaAguaBossEnemy._avisoChao) return;
    if (boss.isMounted && boss.health > 0) {
      boss._brotarTentaculo(position.clone());
    }
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Pisca cada vez mais rápido conforme o golpe se aproxima.
    final fracao = _tempo / SereiaAguaBossEnemy._avisoChao;
    final visivel = (_tempo * (6 + 14 * fracao)).floor().isEven;
    if (!visivel) return;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, _tinta);
  }
}
