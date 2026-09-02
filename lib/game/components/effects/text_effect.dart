import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Texto que se desloca numa direção (pra cima, por padrão) e desaparece
/// depois de um tempo. Usado principalmente pra números de dano em combate,
/// mas serve pra qualquer aviso rápido ("Crítico!", "Bloqueado", etc.).
class TextEffect extends PositionComponent {
  final String text;
  final Vector2 direction;
  final double speed;
  final double duration;
  final Color color;
  final double fontSize;

  double _elapsed = 0.0;

  TextEffect({
    required this.text,
    required Vector2 position,
    Vector2? direction,
    this.speed = 20.0,
    this.duration = 0.8,
    this.color = Palette.branco,
    this.fontSize = 6.0,
  })  : direction = (direction ?? Vector2(0, -1)).normalized(),
        super(position: position.clone(), anchor: Anchor.center, priority: 200);

  /// Atalho pro uso mais comum: número de dano subindo.
  factory TextEffect.dano(
    num valor, {
    required Vector2 position,
    Color color = Palette.branco,
  }) {
    return TextEffect(
      text: valor is int ? '$valor' : valor.toStringAsFixed(0),
      position: position,
      color: color,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position += direction * speed * dt;

    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    //final t = (_elapsed / duration).clamp(0.0, 1.0);
    final alpha = 255;//((1 - t) * 255).round().clamp(0, 255);

    final paint = TextPaint(
      style: TextStyle(
        color: color.withAlpha(alpha),
        fontSize: fontSize,
        fontFamily: 'pixelFont',
        fontWeight: FontWeight.bold,
        shadows: [
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
    );
    paint.render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}
