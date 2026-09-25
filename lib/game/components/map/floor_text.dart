import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';

/// Texto escrito NO CHÃO da sala — tutorial, aviso, o que for.
///
/// Z-order: ser filho do `RoomComponent` já garante a metade de baixo — a sala
/// tem `priority` bem negativo (`_prioridadePiso`), então TUDO dentro dela
/// desenha abaixo de qualquer ator do mundo, qualquer que seja a prioridade
/// interna.
///
/// A metade de cima precisa de número: os detalhes de chão
/// (`_generateFloorDetails`) são `Obstacle`s com `priority = ySortPriority(y)`,
/// que na sala de 192px chega a ~190. Com a prioridade 0 padrão o texto ficava
/// DEBAIXO da grama. [_prioridadeAcimaDoChao] passa de qualquer y possível.
///
/// Quebra de linha própria (por medição, igual `TextEffect`): a tela tem 192px
/// e a `pixelFont` não é monoespaçada, então contar caracteres erraria. `\n` no
/// texto força quebra onde o autor quiser; o resto quebra sozinho.
class FloorText extends PositionComponent {
  final String texto;
  final double larguraMax;
  final double fontSize;

  static final Map<double, TextPaint> _paints = {};

  /// Acima de qualquer `ySortPriority` possível dentro da sala (a sala tem
  /// 192px de altura, então o maior valor gerado é ~192).
  static const int _prioridadeAcimaDoChao = 1000;

  List<String>? _linhas;

  FloorText({
    required this.texto,
    required super.position,
    this.larguraMax = 150.0,
    this.fontSize = 6.0,
  }) : super(anchor: Anchor.center, priority: _prioridadeAcimaDoChao);

  TextPaint get _paint => _paints.putIfAbsent(
    fontSize,
    () => TextPaint(
      style: TextStyle(
        color: Palette.branco,
        fontSize: fontSize,
        fontFamily: 'pixelFont',
        fontWeight: FontWeight.bold,
        // Contorno branco nas 8 direções: o chão muda de cor por bioma, e sem
        // isso o texto desaparece no tileset escuro da caverna.
        shadows: const [
          Shadow(color: Palette.preto, offset: Offset(1, 1)),
          Shadow(color: Palette.preto, offset: Offset(-1, -1)),
          Shadow(color: Palette.preto, offset: Offset(1, -1)),
          Shadow(color: Palette.preto, offset: Offset(-1, 1)),
          Shadow(color: Palette.preto, offset: Offset(0, 1)),
          Shadow(color: Palette.preto, offset: Offset(0, -1)),
          Shadow(color: Palette.preto, offset: Offset(1, 0)),
          Shadow(color: Palette.preto, offset: Offset(-1, 0)),
        ],
      ),
    ),
  );

  @override
  void render(Canvas canvas) {
    final linhas = _linhas ??= _quebrar();
    final alturaLinha = fontSize + 2;
    final topo = -(linhas.length - 1) * alturaLinha / 2;

    for (var i = 0; i < linhas.length; i++) {
      _paint.render(
        canvas,
        linhas[i],
        Vector2(0, topo + i * alturaLinha),
        anchor: Anchor.center,
      );
    }
  }

  List<String> _quebrar() {
    final linhas = <String>[];

    for (final paragrafo in texto.split('\n')) {
      var atual = '';
      for (final palavra in paragrafo.split(' ')) {
        final tentativa = atual.isEmpty ? palavra : '$atual $palavra';
        if (atual.isNotEmpty &&
            _paint.getLineMetrics(tentativa).width > larguraMax) {
          linhas.add(atual);
          atual = palavra;
        } else {
          atual = tentativa;
        }
      }
      linhas.add(atual);
    }

    return linhas;
  }
}
