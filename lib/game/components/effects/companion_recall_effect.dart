import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Efeito de "recall" quando a criatura ativa vai pro banco — por vida
/// zerada em combate (`CreaturesRogueGame.pocketarSlotAtivo`) ou por troca
/// voluntária (`_trocarParaSlot`): um círculo vermelho fecha em cima da
/// posição do jogador, e a bolinha resultante faz um arco até ele mesmo
/// (PIVOT_CONTROLE_DIRETO.md §2.3 — o `Player` não some do mundo, só a
/// criatura que ele estava sendo muda, então a origem e o destino do arco
/// coincidem hoje). Puramente desenhado no Canvas, sem sprite novo.
class CompanionRecallEffect extends PositionComponent {
  /// Lida a cada frame, não capturada uma vez: o treinador anda durante o
  /// arco, e o alvo precisa seguir a posição atual dele, não onde estava no
  /// instante do desmaio.
  final Vector2 Function() trainerPosition;

  static const double _duracaoFechar = 0.3;
  static const double _duracaoArco = 0.4;
  static const double _alturaArco = 16.0;
  static const double _raioBolinha = 1.5;

  final double _raioInicial;
  double _tempo = 0.0;
  late final Vector2 _origem;

  final Paint _paint = Paint()..color = Palette.vermelho..style = PaintingStyle.stroke..strokeWidth = 1..filterQuality = FilterQuality.none ;
  final Paint _paintBorda = Paint()..color = Palette.preto..style = PaintingStyle.stroke..strokeWidth = 1..filterQuality = FilterQuality.none;
  final Paint _paintBorda2 = Paint()..color = Palette.branco..style = PaintingStyle.stroke..strokeWidth = 1..filterQuality = FilterQuality.none;

  CompanionRecallEffect({
    required Vector2 position,
    required this.trainerPosition,
    double raioInicial = 8.0,
  })  : _raioInicial = raioInicial,
        _origem = position.clone(),
        super(position: position.clone(), priority: 200);

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;

    if (_tempo >= _duracaoFechar + _duracaoArco) {
      removeFromParent();
      return;
    }

    if (_tempo > _duracaoFechar) {
      final t = ((_tempo - _duracaoFechar) / _duracaoArco).clamp(0.0, 1.0);
      final destino = trainerPosition();
      final linear = Vector2(
        _origem.x + (destino.x - _origem.x) * t,
        _origem.y + (destino.y - _origem.y) * t,
      );
      // Arco: sobe e desce em cima da linha reta, seno de 0 a π (sobe e
      // volta a zero exatamente na chegada).
      final elevacao = math.sin(t * math.pi) * _alturaArco;
      position = linear - Vector2(0, elevacao);
    }
  }

  @override
  void render(Canvas canvas) {
    final double raio;
    if (_tempo <= _duracaoFechar) {
      final t = (_tempo / _duracaoFechar).clamp(0.0, 1.0);
      raio = _raioInicial * (1 - t);
    } else {
      raio = _raioBolinha;
    }
    if (raio <= 0) return;
    canvas.drawCircle(Offset.zero, raio, _paint);
    canvas.drawCircle(Offset.zero, raio-1, _paintBorda2);
    canvas.drawCircle(Offset.zero, raio+1, _paintBorda);
  }
}
