import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Botão de recolher/liberar o grupo (PIVOT_TREINADOR.md, pedido do
/// usuário) — TOQUE, não segurar: é troca de estado (recolhido/fora), não
/// uma ação contínua como esquiva/captura. Mesmo padrão de
/// `ConsumableSlotButton` (só `TapCallbacks`, dispara no `onTapUp`).
///
/// Sem ícone de sprite — glifo é uma seta desenhada no `render`, primeiro
/// corte, nenhum asset novo.
class RecallButton extends PositionComponent
    with HasGameReference, ComponentViewportMargin, TapCallbacks {
  final VoidCallback onToggle;

  /// Se o grupo tá recolhido agora — só muda a cor/glifo, não o
  /// comportamento do toque (sempre `onToggle`, quem decide direção é
  /// `CreaturesRogueGame.alternarRecuoGrupo`).
  final bool Function() recolhido;

  final Paint _baseColor = Paint()..color = Palette.royal.withAlpha(255);
  final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.none
    ..colorFilter = const ColorFilter.mode(Palette.royal, BlendMode.modulate);

  /// Carregados uma vez em [onLoad], nunca em [render] — `render` é chamado
  /// de forma síncrona pelo motor (não é aguardado), então um `await
  /// Sprite.load(...)` ali dentro desenha no canvas de um frame que já
  /// terminou, e o ícone nunca aparece de forma confiável. Mesmo padrão de
  /// `CompanionPortraitIndicator`.
  Sprite? _spriteLiberar;
  Sprite? _spriteRetorno;

  RecallButton({
    required double radius,
    required this.onToggle,
    required this.recolhido,
    EdgeInsets? margin,
  }) : super(size: Vector2.all(radius * 2)) {
    this.margin = margin;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _spriteLiberar = await Sprite.load('ui/liberar.png');
    _spriteRetorno = await Sprite.load('ui/retorno.png');
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final radius = size.x / 2;
    final dx = point.x - radius;
    final dy = point.y - radius;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void onTapUp(TapUpEvent event) => onToggle();

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.drawCircle(center, radius, _baseColor);

    final iconSize = Vector2.all(size.x * 0.6);
    final sprite = recolhido() ? _spriteLiberar : _spriteRetorno;
    if (sprite != null) {
      sprite.render(
        canvas,
        position: (size - iconSize) / 2,
        size: iconSize,
        overridePaint: _spritePaint,
      );
    }
  }
}
