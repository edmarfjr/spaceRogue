import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/run_save.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

/// Menu inicial: as portas de entrada do jogo. O seletor de controle que
/// morava aqui foi pra [SettingsOverlay], que também persiste a escolha.
class MainMenuOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const MainMenuOverlay({super.key, required this.game});

  void _novoJogo(BuildContext context) {
    game.overlays.remove('MainMenu');
    game.overlays.add(
      CreatureProgress.instance.introConcluida ? 'CreatureSelect' : 'Intro',
    );
  }

  /// "NOVO JOGO" por cima de um save existente apaga a partida em
  /// andamento — mesmo padrão de confirmação de `SettingsOverlay._confirmarReset`
  /// (pergunta antes, não executa direto no toque).
  Future<void> _confirmarNovoJogo(BuildContext context) async {
    if (!RunSave.instance.hasSave) {
      _novoJogo(context);
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.branco,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Palette.preto, width: 2),
        ),
        title: Text(
          context.l10n.menu_confirmarNovoJogoTitulo,
          style: const TextStyle(
            color: Palette.preto,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          context.l10n.menu_confirmarNovoJogoMensagem,
          style: const TextStyle(color: Palette.preto),
        ),
        actions: [
          OutlinedButton(
            onPressed: withBtnSfx(() => Navigator.of(dialogContext).pop(false)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Palette.branco,
              side: BorderSide(color: Palette.preto),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Palette.preto, width: 5),
              ),
            ),
            child: Text(
              context.l10n.settings_confirmarResetNao,
              style: const TextStyle(color: Palette.preto),
            ),
          ),
          OutlinedButton(
            onPressed: withBtnSfx(() => Navigator.of(dialogContext).pop(true)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Palette.branco,
              side: BorderSide(color: Palette.preto),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Palette.preto, width: 5),
              ),
            ),
            child: Text(
              context.l10n.settings_confirmarResetSim,
              style: const TextStyle(
                color: Palette.preto,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmou != true) return;
    await RunSave.instance.apagar();
    if (context.mounted) _novoJogo(context);
  }

  @override
  Widget build(BuildContext context) {
    final estreita = Responsive.ehEstreita(context);
    final temSave = RunSave.instance.hasSave;

    return ResponsiveOverlayScaffold(
      background: Palette.branco,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // `FilterQuality.none` mantém o pixel art nítido na ampliação —
          // mesmo tratamento que todo sprite do jogo já recebe no Flame.
          /*  Image.asset(
            'assets/images/logo.png',
            width: 96,
            height: 96,
            filterQuality: FilterQuality.none,
          ),
          */
          const SizedBox(height: 6),
          Text(
            context.l10n.menu_titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Palette.preto,
              fontSize: estreita ? 32 : 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          if (temSave) ...[
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
              onPressed: withBtnSfx(game.continuarSalva),
              child: Text(
                context.l10n.pause_continuar,
                style: const TextStyle(fontSize: 24, color: Palette.preto),
              ),
            ),
            const SizedBox(height: 10),
          ],
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
            // Sem save: entra direto (mesmo caminho de sempre — seletor de
            // criaturas, ou a intro antes da primeira run). Com save,
            // confirma antes: escolher "novo jogo" por cima de uma run em
            // andamento apaga ela.
            onPressed: withBtnSfx(() => _confirmarNovoJogo(context)),
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
