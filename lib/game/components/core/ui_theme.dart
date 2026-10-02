import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';

/// Cores da "casca" da tela de jogo — tudo que não é o mundo desenhado pela
/// câmera de resolução fixa (160x144). Hoje só a área lateral onde ficam
/// joystick e botões de habilidade (letterbox/pillarbox fora do mapa), mas é
/// o ponto único pra qualquer cor de UI que precise ser trocada depois sem
/// caçar hex espalhado pelo código.
class UiTheme {
  UiTheme._();

  /// Cor que representa cada elemento na INTERFACE.
  ///
  /// Não confundir com `CreatureData.corClara`/`corEscura`, que pintam o
  /// SPRITE de uma criatura específica: duas criaturas de fogo podem ter
  /// tons diferentes, e aqui o que se quer é o contrário — "fogo é laranja"
  /// valendo igual pra todas, pra que a etiqueta de tipo seja reconhecível à
  /// primeira vista.
  static const Map<CreatureType, Color> _porTipo = {
    CreatureType.fogo: Palette.pumpkin,
    CreatureType.planta: Palette.verde,
    CreatureType.agua: Palette.azul,
    CreatureType.eletrico: Palette.amarelo,
    CreatureType.neutro: Palette.cinza,
  };

  static Color corDoTipo(CreatureType tipo) => _porTipo[tipo] ?? Palette.cinza;

  static const Map<CreatureType, Color> _porTipo2 = {
    CreatureType.fogo: Palette.vermelho,
    CreatureType.planta: Palette.forest,
    CreatureType.agua: Palette.royal,
    CreatureType.eletrico: Palette.marrom,
    CreatureType.neutro: Palette.indigo,
  };

  static Color corDoTipo2(CreatureType tipo) => _porTipo2[tipo] ?? Palette.cinza;

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

  ///Cor botões
  static const Color btnCor = Palette.cinza;

  /// Fundo do botão que representa a opção JÁ ESCOLHIDA — o esquema de
  /// controle e o idioma em uso, nas configurações.
  ///
  /// É o único sinal de "este é o ativo" que esses botões têm, então ele
  /// precisa contrastar forte com [btnCor]: se os dois ficarem próximos, a
  /// tela deixa de dizer qual opção está valendo.
  static const Color btnCorAtivo = Palette.preto;

  /// Fundo do menu principal, que cobre a tela inteira e precisa contrastar
  static const Color backgroundMenuCor = Palette.branco;
  static const Color backgroundMenuCor2 = Palette.preto;

  /// Cor de TEXTO dos menus — títulos, rótulos, descrições e o texto dentro
  /// dos botões.
  ///
  /// Existe pra que escurecer [backgroundMenuCor] ou [btnCor] não exija
  /// caçar `color: Palette.preto` por dez arquivos. NÃO cobre o texto
  /// branco de [btnCorAtivo] nem o dos cartões de evolução e aposentadoria,
  /// que são escuros por dentro — aqueles pedem um token próprio se um dia
  /// o tema mudar.
  static const Color txtCor = Palette.preto;
  
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
    this.cor = UiTheme.backgroundMenuCor2,
    this.corExterna,
    this.espessura = 2.0,
    this.vao = 2.0,
  });

  /// Cor da linha de DENTRO, e também da de fora quando [corExterna] é nula.
  /// Por padrão as duas têm a mesma cor: a distinção vem do vão, não do
  /// contraste entre as linhas.
  final Color cor;

  /// Cor só da linha de FORA, quando ela precisa destoar da de dentro — é
  /// como o cartão da criatura selecionada se marca, ganhando um contorno da
  /// cor do próprio elemento (ver `_CartaoCandidata`).
  ///
  /// Marcar seleção por COR, e não por espessura, é o que mantém a geometria
  /// idêntica nos dois estados: [dimensions] não muda, então o conteúdo do
  /// cartão não se mexe nem um pixel quando a seleção troca.
  final Color? corExterna;

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
  ShapeBorder scale(double t) => BordaDupla(
    cor: cor,
    corExterna: corExterna,
    espessura: espessura * t,
    vao: vao * t,
  );

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
    //canvas.drawRect(rect.deflate(espessura / 2), tinta);
    //canvas.drawRect(rect.deflate(espessura * 1.5 + vao), tinta);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(espessura / 2), Radius.circular(5)),
      tinta..color = corExterna ?? cor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(espessura * 1.5 + vao),
        Radius.circular(5),
      ),
      tinta..color = cor,
    );
  }
}


/// A borda dupla na forma de `ShapeBorder`, pra usar no `shape:` de botão.
///
/// Existe separada da [BordaDupla] porque as duas vivem em mundos diferentes
/// do Flutter: aquela é `BoxBorder`, que só entra em `BoxDecoration`; o
/// `shape:` de um `ElevatedButton`/`OutlinedButton` exige `OutlinedBorder`.
/// A alternativa seria embrulhar cada botão num `Container` decorado, o que
/// tiraria o recorte da tinta de toque do botão e deixaria o respingo
/// vazando pra fora da moldura.
///
/// O desenho é o mesmo da [BordaDupla], de propósito: as molduras de caixa e
/// as de botão precisam ser indistinguíveis na tela.
class BordaDuplaShape extends OutlinedBorder {
  const BordaDuplaShape({
    this.cor = UiTheme.backgroundMenuCor2,
    this.espessura = 2.0,
    this.vao = 2.0,
  }) : super(side: BorderSide.none);

  final Color cor;
  final double espessura;
  final double vao;

  /// Raio do arredondamento. Igual ao da [BordaDupla] — se mudar lá, muda
  /// aqui.
  static const double _raio = 5.0;

  /// O conteúdo começa depois das duas linhas E do vão, senão o rótulo do
  /// botão encostaria na linha de dentro.
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(espessura * 2 + vao);

  @override
  BordaDuplaShape copyWith({BorderSide? side, Color? cor, double? espessura, double? vao}) =>
      BordaDuplaShape(
        cor: cor ?? this.cor,
        espessura: espessura ?? this.espessura,
        vao: vao ?? this.vao,
      );

  @override
  ShapeBorder scale(double t) => BordaDuplaShape(
    cor: cor,
    espessura: espessura * t,
    vao: vao * t,
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(_raio)));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        dimensions.resolve(textDirection).deflateRect(rect),
        const Radius.circular(_raio),
      ),
    );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final tinta = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      // Pixel art: nada de suavizar, senão a linha sai cinza nas pontas.
      ..isAntiAlias = false;

    // `deflate(espessura / 2)`: o Canvas centra o traço na linha do caminho,
    // então sem isso metade da linha de fora cairia fora do retângulo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(espessura / 2),
        const Radius.circular(_raio),
      ),
      tinta,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(espessura * 1.5 + vao),
        const Radius.circular(_raio),
      ),
      tinta,
    );
  }
}
