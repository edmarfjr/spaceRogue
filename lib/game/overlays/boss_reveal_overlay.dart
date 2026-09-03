import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:creatures_rogue/game/overlays/creature_select_overlay.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

/// Mostrado uma vez, no começo da run, quando há um boss pendente pra essa
/// run (ver `CreaturesRogueGame.runBoss`). Consentimento informado antes de
/// investir os N andares: você sabe o que te espera e o que ganha ao vencer,
/// mas não sabe SE vai conseguir — a aleatoriedade continua na escolha de
/// qual boss, só a incerteza "será que valeu a pena entrar" que sai.
class BossRevealOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const BossRevealOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final boss = game.runBoss;
    // Sem boss pendente não deveria nem chegar aqui (ver startRun), mas se
    // chegar, não trava a run — só libera igual a um "sem aviso".
    if (boss == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => game.dismissBossReveal(),
      );
      return const SizedBox.shrink();
    }

    final recompensa = CreatureRegistry.byId(boss.creatureId);
    final estreita = Responsive.ehEstreita(context);

    return ResponsiveOverlayScaffold(
      background: Palette.branco,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.bossReveal_vs,
            style: TextStyle(
              color: Palette.preto,
              fontSize: estreita ? 28 : 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          CreatureSprite(creature: recompensa, size: 120, tudoPreto: true),
          const SizedBox(height: 6),
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
            onPressed: withBtnSfx(game.dismissBossReveal),
            child: Text(
              context.l10n.bossReveal_entrar,
              style: const TextStyle(fontSize: 20, color: Palette.preto),
            ),
          ),
        ],
      ),
    );
  }
}
