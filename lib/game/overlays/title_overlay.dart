import 'dart:async';

import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/game_settings.dart';
import 'package:creatures_rogue/game/overlays/selecao_widgets.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

/// Tela de título no estilo da abertura de Pokémon Red/Blue: começa só com
/// uma criatura; o letreiro do nome cai de cima e quica até parar; depois o
/// convite pisca. Enquanto o jogador não toca, as criaturas se revezam — a
/// atual sai pela esquerda e a próxima entra pela direita.
///
/// Só a ABERTURA do app passa por aqui — game over, vitória e pausa voltam
/// direto pro menu (ver `main.dart`), senão o jogador tocaria duas vezes pra
/// chegar onde já queria.
///
/// Toque ou clique em qualquer lugar avança, mesmo no meio da animação; o
/// teclado é tratado no `onKeyEvent` do jogo (ver
/// `CreaturesRogueGame.sairDoTitulo`).
class TitleOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const TitleOverlay({super.key, required this.game});

  @override
  State<TitleOverlay> createState() => _TitleOverlayState();
}

class _TitleOverlayState extends State<TitleOverlay>
    with TickerProviderStateMixin {
  /// Antes do letreiro cair, só a criatura na tela.
  static const _antesDaQueda = Duration(milliseconds: 600);

  /// Quanto cada criatura fica parada antes de sair.
  static const _exibicao = Duration(seconds: 3);

  /// Largura da "janela" por onde as criaturas passam — também a distância
  /// que elas percorrem pra sair e entrar.
  static const double _larguraJanela = 360;
  static const double _ladoCriatura = 160;

  /// De quantos pixels acima o letreiro começa a cair.
  static const double _alturaQueda = 260;

  /// Pisca em degrau (aceso/apagado), não em fade: é o "PRESS START" de
  /// cartucho, e um esmaecer suave leria como carregamento.
  late final AnimationController _pisca = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  /// Queda do letreiro. `bounceOut` é o quique: chega embaixo e dá pulinhos
  /// cada vez menores até assentar.
  late final AnimationController _queda = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Troca de criatura: de 0 a 0,5 a atual sai pela esquerda; de 0,5 a 1 a
  /// próxima entra pela direita.
  late final AnimationController _troca = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Ordem de exibição: todas as criaturas, na forma EVOLUÍDA (a mais
  /// vistosa), embaralhadas a cada abertura do app.
  late final List<CreatureData> _ordem = [
    for (final c in CreatureRegistry.all) c.evoluir?.call() ?? c,
  ]..shuffle();

  int _indice = 0;
  Timer? _espera;

  CreatureData get _atual => _ordem[_indice % _ordem.length];
  CreatureData get _proxima => _ordem[(_indice + 1) % _ordem.length];

  @override
  void initState() {
    super.initState();
    _espera = Timer(_antesDaQueda, () {
      if (!mounted) return;
      _queda.forward();
      _agendarTroca();
    });
  }

  void _agendarTroca() {
    // Aquece o sprite da próxima enquanto a atual está parada: sem isso ela
    // entraria em branco no primeiro quadro, enquanto a paleta é processada.
    _aquecer(_proxima);
    _espera = Timer(_exibicao, () async {
      if (!mounted) return;
      await _troca.forward(from: 0);
      if (!mounted) return;
      setState(() => _indice++);
      _troca.value = 0;
      _agendarTroca();
    });
  }

  void _aquecer(CreatureData c) {
    PaletteSwapper.createSwappedImage(
      imagePath: c.spritePath,
      lightGrayReplacement: c.corClara,
      darkGrayReplacement: c.corEscura,
    );
  }

  @override
  void dispose() {
    _espera?.cancel();
    _pisca.dispose();
    _queda.dispose();
    _troca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final estreita = Responsive.ehEstreita(context);
    // Sem controles na tela, o jogador está de teclado: o convite fala de
    // tecla. Com eles, fala de toque.
    final convite = GameSettings.instance.controlesNaTela
        ? l.titulo_toque
        : l.titulo_tecla;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: withBtnSfx(widget.game.sairDoTitulo),
      child: ResponsiveOverlayScaffold(
        background: UiTheme.backgroundMenuCor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _letreiro(l.menu_titulo, estreita),
              const SizedBox(height: 12),
              _janelaDeCriaturas(),
              const SizedBox(height: 12),
              _convite(convite),
            ],
          ),
        ),
      ),
    );
  }

  Widget _letreiro(String texto, bool estreita) {
    return AnimatedBuilder(
      animation: _queda,
      builder: (context, child) {
        // Escondido até começar a cair: sem isso ele apareceria parado no
        // alto por um instante antes da queda.
        if (_queda.value == 0) return Opacity(opacity: 0, child: child);
        final t = Curves.bounceOut.transform(_queda.value);
        return Transform.translate(
          offset: Offset(0, -_alturaQueda * (1 - t)),
          child: child,
        );
      },
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: UiTheme.txtCor,
          fontSize: estreita ? 32 : 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// A criatura numa janela recortada: ao sair e entrar ela some na borda da
  /// janela, como na tela de Pokémon, em vez de atravessar o resto da tela.
  Widget _janelaDeCriaturas() {
    return ClipRect(
      child: SizedBox(
        width: _larguraJanela,
        height: _ladoCriatura,
        child: AnimatedBuilder(
          animation: _troca,
          builder: (context, _) {
            final v = _troca.value;
            final saindo = v < 0.5;
            final criatura = saindo ? _atual : _proxima;
            final dx = saindo
                ? -_larguraJanela * Curves.easeIn.transform(v / 0.5)
                : _larguraJanela *
                      (1 - Curves.easeOut.transform((v - 0.5) / 0.5));
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Center(
                child: SpriteUi(
                  caminho: criatura.spritePath,
                  tamanho: _ladoCriatura,
                  cor1: criatura.corClara,
                  cor2: criatura.corEscura,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// O convite só aparece depois que o letreiro assentou — antes disso a
  /// tela ainda está "se montando".
  Widget _convite(String texto) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pisca, _queda]),
      builder: (context, _) {
        final aceso = _queda.isCompleted && _pisca.value < 0.6;
        return Opacity(
          opacity: aceso ? 1.0 : 0.0,
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UiTheme.txtCor,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        );
      },
    );
  }
}
