import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';

/// Varredura de tentáculo em arco em volta de [dono] — o golpe corpo a corpo
/// do Calamarin (habilidade 1) e dos inimigos dele.
///
/// Não é projétil: não voa, não colide. O acerto é GEOMÉTRICO, a cada quadro:
/// quem estiver a até [alcance] do dono e dentro do ângulo já varrido leva o
/// golpe, uma vez só por varredura. Assim o arco de 120° e o giro de 360° do
/// Redemoinho saem da mesma conta, sem caso especial.
///
/// O sprite (`projeteis/tentaculo.png`, desenhado apontando pra CIMA) gira
/// com a base presa no dono, então a ponta descreve o arco que o jogador vê.
class GolpeDeTentaculo extends PositionComponent {
  final PositionComponent dono;

  /// Direção do CENTRO do arco (a mira).
  final Vector2 direcao;

  /// Ângulo total varrido, em radianos (2π = volta inteira).
  final double arco;

  /// +1 varre no sentido do relógio, -1 no contrário.
  final double sentido;

  final double duracao;
  final double alcance;
  final double dano;
  final double empurrao;
  final CreatureType tipo;

  /// `true`: golpe de inimigo, acerta o jogador. `false`: acerta inimigos.
  final bool isEnemy;

  /// Quem golpeou, pro "derrotado por" — só faz sentido com [isEnemy].
  final CreatureData? origem;

  final Color cor1;
  final Color cor2;

  final Set<PositionComponent> _atingidos = {};
  double _tempo = 0.0;
  late final double _anguloInicial;
  SpriteComponent? _visual;

  GolpeDeTentaculo({
    required this.dono,
    required this.direcao,
    required this.arco,
    required this.duracao,
    required this.alcance,
    required this.dano,
    required this.tipo,
    required this.cor1,
    required this.cor2,
    this.sentido = 1.0,
    this.empurrao = 30.0,
    this.isEnemy = false,
    this.origem,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final mira = direcao.length == 0 ? Vector2(0, 1) : direcao.normalized();
    _anguloInicial = atan2(mira.y, mira.x) - sentido * arco / 2;
    position = dono.absolutePosition.clone();

    final img = await PaletteSwapper.createSwappedImage(
      imagePath: 'projeteis/tentaculo.png',
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
    );
    final visual = SpriteComponent(
      sprite: Sprite(img),
      size: Vector2(alcance * 0.75, alcance),
      // Base do tentáculo no centro do dono: girar em volta dela faz a ponta
      // varrer o arco.
      anchor: Anchor.bottomCenter,
    );
    _visual = visual;
    add(visual);
    _posicionar(0.0);
  }

  /// Ângulo atual da ponta, em radianos matemáticos (0 = direita).
  double _anguloEm(double fracao) => _anguloInicial + sentido * arco * fracao;

  void _posicionar(double fracao) {
    position = dono.absolutePosition.clone();
    priority = ySortPriority(position.y) + 1;
    // O sprite aponta pra cima (-y), que é o ângulo matemático -π/2; somar
    // π/2 converte "pra onde a ponta vai" em rotação do componente.
    _visual?.angle = _anguloEm(fracao) + pi / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!dono.isMounted) {
      removeFromParent();
      return;
    }

    _tempo += dt;
    final fracao = (_tempo / duracao).clamp(0.0, 1.0);
    _posicionar(fracao);
    _acertar(arco * fracao);

    if (_tempo >= duracao) removeFromParent();
  }

  /// Quanto do arco o alvo em [ponto] está "depois" do início da varredura,
  /// no sentido dela — de 0 a 2π.
  double _anguloPercorridoAte(Vector2 ponto) {
    final rel = ponto - dono.absolutePosition;
    final alvo = atan2(rel.y, rel.x);
    final diff = (alvo - _anguloInicial) * sentido;
    return diff % (2 * pi);
  }

  bool _alcanca(Vector2 ponto, double varrido) {
    if (ponto.distanceTo(dono.absolutePosition) > alcance) return false;
    return _anguloPercorridoAte(ponto) <= varrido;
  }

  void _acertar(double varrido) {
    if (isEnemy) {
      final d = dono;
      if (d is! Enemy) return;
      final jogador = d.playerTarget;
      if (_atingidos.contains(jogador)) return;
      // Pulando ou enterrado, o tentáculo passa por baixo/por cima.
      if (jogador.isAirborne || jogador.submerso) return;
      if (!_alcanca(jogador.absolutePosition, varrido)) return;
      _atingidos.add(jogador);
      jogador.takeDamage(dano, tipo, origem: origem);
      jogador.applyKnockback(dono.absolutePosition, empurrao);
      return;
    }

    final inimigos =
        dono.parent?.children.whereType<Enemy>() ?? const <Enemy>[];
    for (final inimigo in inimigos.toList()) {
      if (_atingidos.contains(inimigo)) continue;
      if (inimigo.summonTimer > 0 || inimigo.health <= 0) continue;
      if (!_alcanca(inimigo.absolutePosition, varrido)) continue;
      _atingidos.add(inimigo);
      // Mesmos multiplicadores do projétil do jogador; crítico e bônus de
      // elemento já saem de dentro do `Enemy.takeDamage`.
      inimigo.takeDamage(
        dano * Player.danoMult * Player.danoMultDerivado,
        tipoAtacante: tipo,
      );
      inimigo.applyKnockback(dono.absolutePosition, empurrao);
    }
  }
}
