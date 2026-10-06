import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/game_settings.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

/// Tela de título: logo, nome e o convite piscando. Só a ABERTURA do app
/// passa por aqui — game over, vitória e pausa voltam direto pro menu (ver
/// `main.dart`), senão o jogador tocaria duas vezes pra chegar onde já
/// queria.
///
/// Toque ou clique em qualquer lugar avança; o teclado é tratado no
/// `onKeyEvent` do jogo (ver `CreaturesRogueGame.sairDoTitulo`).
class TitleOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const TitleOverlay({super.key, required this.game});

  @override
  State<TitleOverlay> createState() => _TitleOverlayState();
}

class _TitleOverlayState extends State<TitleOverlay>
    with SingleTickerProviderStateMixin {
  /// Pisca em degrau (aceso/apagado), não em fade: é o "PRESS START" de
  /// cartucho, e um esmaecer suave leria como carregamento.
  late final AnimationController _pisca = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _pisca.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // `FilterQuality.none` mantém o pixel art nítido na ampliação.
            Image.asset(
              'assets/images/logo.png',
              width: 96,
              height: 96,
              filterQuality: FilterQuality.none,
            ),
            const SizedBox(height: 6),
            Text(
              l.menu_titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: UiTheme.txtCor,
                fontSize: estreita ? 32 : 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _pisca,
              builder: (context, _) => Opacity(
                opacity: _pisca.value < 0.6 ? 1.0 : 0.0,
                child: Text(
                  convite,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: UiTheme.txtCor,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
