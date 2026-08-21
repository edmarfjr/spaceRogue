import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) => game.dismissBossReveal());
      return const SizedBox.shrink();
    }

    final recompensa = CreatureRegistry.byId(boss.creatureId);

    return Material(
      color: Palette.branco,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ANDAR ${CreaturesRogueGame.andaresPorBoss}: BOSS',
              style: const TextStyle(color: Palette.preto, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              boss.nome,
              style: const TextStyle(color: Palette.preto, fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
           
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
              onPressed: game.dismissBossReveal,
              child: const Text(' ENTRAR ', style: TextStyle(fontSize: 20, color: Palette.preto)),
            ),
          ],
        ),
      ),
    );
  }
}
