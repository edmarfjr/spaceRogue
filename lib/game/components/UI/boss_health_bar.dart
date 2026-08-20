import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';

/// Barra de vida do boss, desenhada na parte de baixo da viewport da câmera
/// (espaço de 160x144, o mesmo dos corações). Sem ela a luta de boss não tem
/// leitura de progresso — bater num saco de pancada com 96 de vida parece
/// interminável.
///
/// Se auto-remove quando o boss sai do mundo, então quem spawna o boss só
/// precisa adicionar a barra e esquecer dela.
class BossHealthBar extends PositionComponent {
  final Enemy boss;
  final String nome;

  static final Vector2 _tamanhoBarra = Vector2(120, 6);

  late final TextPaint _textPaint;

  final Paint _moldura = Paint()..color = Palette.preto;
  final Paint _fundo = Paint()..color = Palette.cinzaEsc;
  final Paint _preenchimento = Paint()..color = Palette.vermelho;

  BossHealthBar({required this.boss, required this.nome})
      : super(
          // Centralizada na horizontal (160 de largura), rente ao pé da tela.
          position: Vector2((192 - _tamanhoBarra.x) / 2, 170),
          size: _tamanhoBarra.clone(),
          priority: 100,
        );

  @override
  Future<void> onLoad() async {
    _textPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'pixelFont',
        color: Palette.branco,
        fontSize: 8,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Palette.preto, offset: Offset(1, 1))],
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    // O boss morreu (ou a run foi reiniciada): a barra vai junto.
    if (boss.isRemoved) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final fracao = (boss.health / boss.maxHealth).clamp(0.0, 1.0);

    canvas.drawRect(Rect.fromLTWH(-1, -1, size.x + 2, size.y + 2), _moldura);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _fundo);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x * fracao, size.y), _preenchimento);

    _textPaint.render(
      canvas,
      nome,
      Vector2(size.x / 2, -2),
      anchor: Anchor.bottomCenter,
    );
  }
}
