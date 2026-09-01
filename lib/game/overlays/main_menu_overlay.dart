import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
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
    return Material(
      color: Palette.branco,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.menu_titulo,
              style: const TextStyle(color: Palette.preto, fontSize: 48, fontWeight: FontWeight.bold),
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
                  CreatureProgress.instance.introConcluida ? 'CreatureSelect' : 'Intro',
                );
              }),
              child: Text(context.l10n.menu_novoJogo, style: const TextStyle(fontSize: 24, color: Palette.preto)),
            ),
            const SizedBox(height: 15),
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
              child: Text(context.l10n.menu_configuracoes, style: const TextStyle(fontSize: 20, color: Palette.preto)),
            ),
          ],
        ),
      ),
    );
  }
}
