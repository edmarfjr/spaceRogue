import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/UI/dynamic_joystick_component.dart';
import 'package:creatures_rogue/game/components/UI/pause_button_sprite.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class HudOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final botao = _PauseButton(
      onPressed: withBtnSfx(() {
        game.pauseEngine(); // Congela o jogo inteiro!
        game.overlays.add('PauseMenu');
      }),
    );

    final tela = MediaQuery.sizeOf(context);
    final retrato = DynamicJoystickComponent.retrato(
      Vector2(tela.width, tela.height),
    );

    // PAISAGEM: canto superior direito, de sempre. `SafeArea` aqui, não um
    // `Padding` fixo por fora: numa tela com entalhe ou cantos arredondados
    // (celular), o botão não pode nascer embaixo do recorte do sistema.
    if (!retrato) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(padding: const EdgeInsets.all(2), child: botao),
        ),
      );
    }

    // RETRATO: a área de jogo ocupa o topo inteiro (ver
    // `CreaturesRogueGame._reflowControles`) — o botão migra pra dentro da
    // banda de controle do rodapé, pra não ficar em cima do jogo. Centro
    // horizontal (não `left`/`right` fixo): os slots do inventário moram na
    // ponta esquerda da banda e a habilidade 2 na ponta direita (ver
    // `CreaturesRogueGame._reflowControles`/`_setupActionButtons`) — o meio é
    // o único ponto que não briga com nenhum dos dois em qualquer tamanho de
    // tela. Mesma conta de altura de banda que o joystick usa, senão os dois
    // calculam a orientação/altura cada um à sua moda e um dia descolam.
    final alturaBanda = DynamicJoystickComponent.alturaBanda(
      Vector2(tela.width, tela.height),
    );
    return Stack(
      children: [
        Positioned(
          top: tela.height - alturaBanda + 24,
          left: 0,
          right: 0,
          child: Center(child: botao),
        ),
      ],
    );
  }
}

/// Botão de pausa: sprite de dois quadros já com a paleta trocada (ver
/// `PauseButtonSprite`) — neutro e pressionado. `StatefulWidget` só pra
/// isso — o `HudOverlay` não precisa saber de estado de toque, só de
/// posição.
class _PauseButton extends StatefulWidget {
  final VoidCallback? onPressed;
  const _PauseButton({required this.onPressed});

  @override
  State<_PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<_PauseButton> {
  static const double _tamanho = 96;

  bool _pressionado = false;

  void _setPressionado(bool valor) {
    if (_pressionado == valor) return;
    setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressionado(true),
      onTapUp: (_) {
        _setPressionado(false);
        widget.onPressed?.call();
      },
      onTapCancel: () => _setPressionado(false),
      child: SizedBox(
        width: _tamanho,
        height: _tamanho,
        child: CustomPaint(painter: _PauseButtonPainter(_pressionado)),
      ),
    );
  }
}

/// Recorta o quadro certo (`Canvas.drawImageRect`) direto da imagem já
/// paletizada — mais simples e exato que o truque de `DecorationImage`
/// (escalar a tira inteira e confiar no `BoxFit`/`alignment` pra cortar).
class _PauseButtonPainter extends CustomPainter {
  final bool pressionado;
  _PauseButtonPainter(this.pressionado);

  static final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  @override
  void paint(Canvas canvas, Size size) {
    final imagem = PauseButtonSprite.imagem;
    final larguraQuadro = imagem.height.toDouble();
    final alturaQuadro = imagem.height.toDouble();
    final origem = Rect.fromLTWH(
      pressionado ? larguraQuadro : 0,
      0,
      larguraQuadro,
      alturaQuadro,
    );
    final destino = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(imagem, origem, destino, _paint);
  }

  @override
  bool shouldRepaint(covariant _PauseButtonPainter oldDelegate) =>
      oldDelegate.pressionado != pressionado;
}
