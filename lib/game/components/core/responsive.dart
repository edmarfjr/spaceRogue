import 'package:flutter/material.dart';

/// Helpers de responsividade compartilhados por todos os overlays
/// (`lib/game/overlays/*.dart`) — um lugar só, pra não resolver "que largura
/// cabe" oito vezes com números diferentes. Os overlays são Flutter normal
/// por cima do canvas do jogo (resolução fixa 160x144), então precisam se
/// virar sozinhos em qualquer tamanho de janela/tela.
class Responsive {
  Responsive._();

  /// Abaixo disso a janela é "estreita" — celular em retrato, ou uma janela
  /// de desktop redimensionada bem pequena. Layout lado a lado
  /// (sidebar+painel, cards numa fileira) precisa empilhar ou quebrar linha
  /// aqui em vez de manter a largura fixa que o rascunho original pedia.
  static const double larguraEstreita = 480;

  static bool ehEstreita(BuildContext context) =>
      MediaQuery.sizeOf(context).width < larguraEstreita;

  /// Encolhe [desejada] pra caber na largura real da tela, nunca crescendo
  /// além do valor original — é pra containers com `width:` fixo hoje (ex.:
  /// a caixa de diálogo da intro), que foram desenhados pra uma largura de
  /// referência mas não podem estourar numa tela menor que ela.
  static double largura(
    BuildContext context,
    double desejada, {
    double fracaoTela = 0.92,
  }) {
    final disponivel = MediaQuery.sizeOf(context).width * fracaoTela;
    return desejada > disponivel ? disponivel : desejada;
  }
}

/// Moldura comum pros overlays em formato "cartão centralizado" (menu
/// principal, configurações, pausa, game over, boss reveal): todos eram
/// `Material` + `Center` + `Column(mainAxisSize: min)` sem rede de segurança
/// nenhuma — em janela baixa (celular em landscape, ou desktop bem baixo)
/// um cartão mais alto que a tela estourava ("BOTTOM OVERFLOWED"), e nenhum
/// respeitava entalhe/cantos arredondados de celular.
///
/// Resolve os dois problemas sem mudar o conteúdo de cada tela:
/// - `SafeArea` — não desenha embaixo de entalhe/barra de sistema.
/// - `FittedBox(fit: scaleDown)` — em vez de rolar, ENCOLHE o cartão
///   inteiro (texto, botões, espaçamento, tudo junto e proporcional) até
///   caber na tela. Testado no Moto G84: a versão anterior (scroll) deixava
///   sobra de tela em branco e um dedo extra pra rolar; encolher elimina o
///   scroll de vez, sem cortar nada. Nunca amplia além do tamanho original
///   quando já cabe — só age quando estoura.
/// - `ConstrainedBox(maxWidth)` — largura de referência do cartão; numa tela
///   larga ele para de crescer, numa estreita o `FittedBox` encolhe o resto.
class ResponsiveOverlayScaffold extends StatelessWidget {
  final Color background;
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveOverlayScaffold({
    super.key,
    required this.child,
    this.background = Colors.transparent,
    this.maxWidth = 480,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
