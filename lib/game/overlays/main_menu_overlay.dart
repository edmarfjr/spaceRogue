import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

/// Menu inicial: só as duas portas de entrada do jogo. O seletor de controle
/// que morava aqui foi pra [SettingsOverlay], que também persiste a escolha.
class MainMenuOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final estreita = Responsive.ehEstreita(context);

    return ResponsiveOverlayScaffold(
      background: Palette.branco,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // `FilterQuality.none` mantém o pixel art nítido na ampliação —
          // mesmo tratamento que todo sprite do jogo já recebe no Flame.
          Image.asset(
            'assets/images/logo.png',
            width: 96,
            height: 96,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.menu_titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Palette.preto,
              fontSize: estreita ? 32 : 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.branco,
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Palette.preto, width: 2),
              ),
            ),
            onPressed: withBtnSfx(() {
              // Leva pro seletor de criaturas. A run só começa de fato
              // (e o motor só despausa) quando uma criatura é escolhida.
              //
              // Antes da primeira run não há nada pra selecionar: nenhuma
              // criatura está liberada. Aí o caminho é a intro, que
              // apresenta o mundo e termina liberando a criatura inicial.
              game.overlays.remove('MainMenu');
              game.overlays.add(
                CreatureProgress.instance.introConcluida
                    ? 'CreatureSelect'
                    : 'Intro',
              );
            }),
            child: Text(
              context.l10n.menu_novoJogo,
              style: const TextStyle(fontSize: 24, color: Palette.preto),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.branco,
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Palette.preto, width: 2),
              ),
            ),
            onPressed: withBtnSfx(() {
              game.overlays.remove('MainMenu');
              game.settingsReturnOverlay = 'MainMenu';
              game.overlays.add('Settings');
            }),
            child: Text(
              context.l10n.menu_configuracoes,
              style: const TextStyle(fontSize: 20, color: Palette.preto),
            ),
          ),
        ],
      ),
    );
  }
}
