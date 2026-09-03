import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/l10n/ability_passive_i18n.dart';
import 'package:creatures_rogue/l10n/creature_i18n.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'creature_select_overlay.dart' show CreatureSprite;

class PauseMenuOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const PauseMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ResponsiveOverlayScaffold(
      background: Palette.preto.withOpacity(0.7),
      // Um pouco mais larga que o padrão: os cards de equipe (ver
      // `_EquipeRow`) precisam de espaço pra caber 2-3 lado a lado antes de
      // `Wrap` empilhar.
      maxWidth: 640,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Palette.branco,
          border: Border.all(color: Palette.preto, width: 4),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.pause_jogoPausado,
              style: const TextStyle(color: Palette.preto, fontSize: 32),
            ),
            const SizedBox(height: 5),
            _EquipeRow(game: game),
            const SizedBox(height: 5),
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
                game.overlays.remove('PauseMenu');
                game.resumeEngine();
              }),
              child: Text(
                context.l10n.pause_continuar,
                style: const TextStyle(fontSize: 20, color: Palette.preto),
              ),
            ),
            const SizedBox(height: 5),
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
              // Motor continua pausado: só troca de overlay. `VOLTAR` em
              // `SettingsOverlay` lê `settingsReturnOverlay` pra saber que
              // precisa reabrir o PauseMenu, não o MainMenu.
              onPressed: withBtnSfx(() {
                game.overlays.remove('PauseMenu');
                game.settingsReturnOverlay = 'PauseMenu';
                game.overlays.add('Settings');
              }),
              child: Text(
                context.l10n.pause_configuracoes,
                style: const TextStyle(fontSize: 20, color: Palette.preto),
              ),
            ),
            const SizedBox(height: 5),
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
                game.overlays.remove('PauseMenu');
                game.overlays.remove('Hud');
                game.overlays.add('MainMenu');
                // Chama a sua função de limpar/reiniciar a fase!
                //game.resetGame();
              }),
              child: Text(
                context.l10n.pause_sairParaMenu,
                style: const TextStyle(fontSize: 20, color: Palette.preto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fileira com um card por slot do grupo (até 3 — ver
/// `CreaturesRogueGame.maxCompanions`). Lê `companionCreatures`, não
/// `companions`: a criatura recolhida no bolso continua no grupo (a passiva
/// dela continua valendo, ver PIVOT_TREINADOR.md) e precisa aparecer aqui
/// igual a uma fora do bolso — só marcada como "no bolso". Slot vazio (grupo
/// ainda não completo) não desenha card nenhum.
class _EquipeRow extends StatelessWidget {
  final CreaturesRogueGame game;
  const _EquipeRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[];
    for (int i = 0; i < game.companionCreatures.length; i++) {
      final creature = game.companionCreatures[i];
      if (creature == null) continue;
      slots.add(
        _EquipeCard(
          creature: creature,
          pocketed: game.companionPocketed[i],
          ativa: i == game.companionAtivoIndex,
        ),
      );
    }
    if (slots.isEmpty) return const SizedBox.shrink();

    // `Wrap`, não `Row`: até 3 cards de 220-280px lado a lado não cabem numa
    // janela estreita — `Wrap` empilha em vez de estourar a largura.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: slots,
    );
  }
}

class _EquipeCard extends StatelessWidget {
  final CreatureData creature;
  final bool pocketed;
  final bool ativa;
  const _EquipeCard({
    required this.creature,
    required this.pocketed,
    required this.ativa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 280 é a largura "de design"; numa tela muito estreita, `Wrap` só
      // ajuda quando o card em si já cabe — `Responsive.largura` encolhe o
      // card antes de precisar quebrar linha.
      width: Responsive.largura(context, 280),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Palette.branco,
        border: Border.all(color: Palette.preto, width: ativa ? 3 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CreatureSprite(creature: creature, size: 40),
          const SizedBox(height: 4),
          Text(
            creatureName(context, creature.id),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Palette.preto,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (pocketed)
            Text(
              context.l10n.pause_noBolso,
              style: const TextStyle(color: Palette.cinzaEsc, fontSize: 9),
            ),
          const SizedBox(height: 4),
          Text(
            context.l10n.pause_habilidade(
              abilityName(context, creature.ability1),
              abilityDescription(context, creature.ability1),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.preto, fontSize: 9),
          ),
          Text(
            context.l10n.pause_habilidade(
              abilityName(context, creature.ability2),
              abilityDescription(context, creature.ability2),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.preto, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
