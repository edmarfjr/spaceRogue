import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/items/consumable_item.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Um dos dois slots de item de uso único. Clicar usa o item que está dentro.
///
/// Por que NÃO herda o esquema do [AbilityButton]: aquele botão também ativa
/// quando um dedo já apoiado na tela *desliza* para dentro dele (ver
/// PointerTracker). Pra habilidade isso é recurso; pra item de uso único seria
/// item queimado por acidente. Aqui é só `TapCallbacks`, e de propósito no
/// `onTapUp` — arrastar o dedo pra fora cancela o toque e o item não é gasto.
///
/// Fica na faixa de [alturaFaixa] px reservada no topo da tela. Essa faixa
/// existe porque os dois esquemas de controle cobrem a tela inteira (joystick
/// na metade esquerda, `GestureActionArea` na direita, ambos de altura total):
/// um slot sobreposto ao esquema de gestos dispararia a habilidade 1 no mesmo
/// toque que usa o item.
class ConsumableSlotButton extends PositionComponent
    with HasGameReference, ComponentViewportMargin, TapCallbacks {
  /// Altura reservada no topo da tela para o inventário. O joystick e a área
  /// de gestos descontam isso da própria altura.
  static const double alturaFaixa = 72.0;

  /// Lido a cada frame: o slot é montado no onLoad do jogo, antes de existir
  /// jogador, e o conteúdo muda a cada item pego ou usado.
  final ConsumableType? Function() conteudo;

  final VoidCallback onUsar;

  final Map<ConsumableType, Sprite> _sprites = {};

  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.none;
  final Paint _fundoVazio = Paint()..color = Palette.cinzaEsc.withAlpha(120);
  final Paint _fundoCheio = Paint()..color = Palette.cinzaEsc.withAlpha(200);
  final Paint _borda = Paint()
    ..color = Palette.branco.withAlpha(160)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  ConsumableSlotButton({
    required double radius,
    required this.conteudo,
    required this.onUsar,
    EdgeInsets? margin,
  }) : super(size: Vector2.all(radius * 2)) {
    this.margin = margin;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Os três sprites são gerados uma vez por slot, no carregamento — trocar a
    // paleta em pleno combate, na hora de pegar o item, daria travadinha.
    for (final tipo in ConsumableType.values) {
      final img = await PaletteSwapper.createSwappedImage(
        imagePath: tipo.spritePath,
        lightGrayReplacement: tipo.cor1,
        darkGrayReplacement: tipo.cor2,
      );
      _sprites[tipo] = Sprite(img);
    }
  }

  /// Área de toque circular, igual ao círculo desenhado (mesma razão do
  /// AbilityButton: o retângulo padrão daria cantos clicáveis fora do visual).
  @override
  bool containsLocalPoint(Vector2 point) {
    final radius = size.x / 2;
    final dx = point.x - radius;
    final dy = point.y - radius;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (conteudo() != null) onUsar();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    //final radius = size.x / 2;
    final tipo = conteudo();

    //canvas.drawCircle(center, radius, tipo == null ? _fundoVazio : _fundoCheio);
    //canvas.drawCircle(center, radius - 1, _borda);

    canvas.drawRect(Rect.fromCenter(center: center, width:  size.x, height:  size.y), tipo == null ? _fundoVazio : _fundoCheio);
    canvas.drawRect(Rect.fromCenter(center: center, width:  size.x, height:  size.y), _borda);

    if (tipo == null) return;

    final iconSize = Vector2.all(size.x * 0.6);
    _sprites[tipo]?.render(
      canvas,
      position: (size - iconSize) / 2,
      size: iconSize,
      overridePaint: _spritePaint,
    );
  }
}
