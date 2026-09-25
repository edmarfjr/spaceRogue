import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';

/// Contador de `Player.cargasDeSala` na Hud: uma fileirinha de quadradinhos,
/// um por carga possível, acesos até a quantidade que o jogador tem.
///
/// Quadradinhos e não número: o texto da Hud é fonte 12 numa tela de 160x144,
/// grande demais pra caber ao lado do anel de cooldown sem brigar com o andar
/// e as moedas. A contagem vai no máximo até 6, e nesse alcance a fileira é
/// mais rápida de ler que o algarismo.
///
/// Fica INVISÍVEL quando nenhum item em mãos gasta carga (ver
/// [deveAparecer]): sem isso, todo jogador veria um medidor que não faz nada.
///
/// Uma LINHA por uso guardado: cada fileira de [custo] quadradinhos é uma
/// carga completa. Empilhadas, e não em sequência — assim "tenho dois usos"
/// se lê pela altura da pilha, sem contar quadradinho por quadradinho.
class CargaSalaIndicator extends PositionComponent {
  CargaSalaIndicator({
    required this.cargas,
    required this.maximo,
    required this.custo,
    required this.deveAparecer,
    super.position,
  }) : super(
         size: Vector2(
           custo * _lado + (custo - 1) * _espaco,
           ((maximo + custo - 1) ~/ custo) * (_lado + _espaco) - _espaco,
         ),
       );

  /// Quantas cargas o jogador tem agora.
  final int Function() cargas;

  /// Teto da reserva — define quantos quadradinhos existem.
  final int maximo;

  /// Quantas cargas um uso consome — é o que define quantos quadradinhos
  /// cabem em cada linha.
  final int custo;

  final bool Function() deveAparecer;

  static const double _lado = 2.0;
  static const double _espaco = 1.0;

  final Paint _cheio = Paint()..color = Palette.laranja;
  final Paint _vazio = Paint()..color = Palette.cinzaEsc.withAlpha(160);

  @override
  void render(Canvas canvas) {
    if (!deveAparecer()) return;

    final quantidade = cargas();

    for (var i = 0; i < maximo; i++) {
      final linha = i ~/ custo;
      final coluna = i % custo;

      canvas.drawRect(
        Rect.fromLTWH(
          coluna * (_lado + _espaco),
          linha * (_lado + _espaco),
          _lado,
          _lado,
        ),
        i < quantidade ? _cheio : _vazio,
      );
    }
  }
}
