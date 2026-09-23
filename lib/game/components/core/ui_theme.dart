import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Cores da "casca" da tela de jogo — tudo que não é o mundo desenhado pela
/// câmera de resolução fixa (160x144). Hoje só a área lateral onde ficam
/// joystick e botões de habilidade (letterbox/pillarbox fora do mapa), mas é
/// o ponto único pra qualquer cor de UI que precise ser trocada depois sem
/// caçar hex espalhado pelo código.
class UiTheme {
  UiTheme._();

  /// Preenche a tela inteira atrás do mundo do jogo — visível nas margens
  /// laterais onde os controles ficam, já que o mapa só ocupa a resolução
  /// fixa da câmera. Cinza claro = plástico do Game Boy original.
  static const Color screenBackground = Palette.cinza;

  /// Moldura escura ao redor da área jogável — o "vão" preto que cerca a
  /// tela de LCD no Game Boy de verdade, separando o plástico do shell do
  /// conteúdo da tela.
  static const Color screenBezel = Palette.preto;

  /// Cores da cápsula do botão de pause (estilo START/SELECT do Game Boy).
  static const Color pauseCapsuleCor1 = Palette.indigo;
  static const Color pauseCapsuleCor2 = Palette.azulEsc;

  /// Cores do botão de ação e (estilo A/B do Game Boy).
  static const Color actionButtonCor1 = Palette.burgundy;
  static const Color actionButtonCor2 = Palette.roxoEsc;

  /// Cores do dpad.
  static const Color dpadCor1 = Palette.cinzaEsc;
  static const Color dpadCor2 = Palette.azulEsc;

  /// Cores do apad.
  static const Color apadCor1 = Palette.burgundy;
  static const Color apadCor2 = Palette.roxoEsc;
  
}

/// Borda de DUAS linhas com um vão entre elas — o quadro clássico de caixa de
/// Game Boy, usado nos painéis e cards dos overlays.
///
/// É um [BoxBorder] de verdade, e não um widget que embrulha o conteúdo, por
/// um motivo prático: assim cada tela troca UMA linha
/// (`border: Border.all(...)` vira `border: const BordaDupla(...)`) e nada na
/// árvore de widgets muda. Embrulhar exigiria mexer no layout de cada painel,
/// que é onde moram os `FittedBox`/`Expanded` que já foram ajustados no
/// aparelho.
///
/// O vão não é pintado: o `BoxDecoration` desenha o `color` dele por baixo da
/// borda inteira, então entre as duas linhas aparece o próprio fundo do
/// painel. Painel sem `color` deixa passar o que estiver atrás, que é o
/// comportamento esperado nos cards transparentes.
///
/// Só desenha CANTO RETO. Toda a UI do jogo usa `BorderRadius.zero` (é pixel
/// art), e suportar raio aqui seria código sem chamador.
@immutable
class BordaDupla extends BoxBorder {
  const BordaDupla({
    this.cor = Palette.preto,
    this.espessura = 2.0,
    this.vao = 2.0,
  });

  /// Cor das duas linhas. Elas têm a mesma cor de propósito: a distinção vem
  /// do vão, não do contraste entre as linhas.
  final Color cor;

  /// Espessura de CADA linha.
  final double espessura;

  /// Distância entre a linha de fora e a de dentro.
  final double vao;

  BorderSide get _lado => BorderSide(color: cor, width: espessura);

  @override
  BorderSide get top => _lado;
  @override
  BorderSide get bottom => _lado;

  /// O conteúdo começa depois das duas linhas E do vão — senão o texto do
  /// painel encostaria na linha de dentro.
  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(espessura * 2 + vao);

  @override
  bool get isUniform => true;

  @override
  ShapeBorder scale(double t) =>
      BordaDupla(cor: cor, espessura: espessura * t, vao: vao * t);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(dimensions.resolve(textDirection).deflateRect(rect));

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final tinta = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      // Pixel art: nada de suavizar a linha, senão a borda sai cinza nas
      // pontas em vez de preta.
      ..isAntiAlias = false;

    // `deflate(espessura / 2)`: o Canvas centra o traço na linha do caminho,
    // então sem isso metade da linha de fora cairia fora do retângulo e
    // sumiria no corte do widget.
    canvas.drawRect(rect.deflate(espessura / 2), tinta);
    canvas.drawRect(rect.deflate(espessura * 1.5 + vao), tinta);
  }
}
