import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

class GameOverMenu extends StatelessWidget {
  final CreaturesRogueGame game;
  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
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
              context.l10n.gameOver_titulo,
              style: const TextStyle(color: Palette.preto, fontSize: 50, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
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
                // 1. Remove a tela de Game Over
                game.overlays.remove('GameOver');
                // 2. Chama a função de limpar e resetar variáveis
                game.resetGame();
                // 3. Volta o botão de Pause e descongela o jogo
                game.overlays.add('Hud');
                game.resumeEngine();
              }),
              child: Text(context.l10n.gameOver_restart, style: const TextStyle(fontSize: 20, color: Palette.preto)),
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
                game.overlays.remove('GameOver');
                // Sem resetGame() aqui: chamar startRun (via resetGame) só pra
                // esconder a run atrás do menu criava dois "startRun" em
                // sequência com o motor pausado, e o Player/Companion da run
                // morta sobrevivia junto com o novo (ver PIVOT_TREINADOR.md).
                // O CreatureSelectOverlay já chama startRun quando o jogador
                // de fato escolhe jogar de novo — essa run parada e pausada
                // fica só esperando, sem custo de gameplay nenhum.
                game.overlays.add('MainMenu'); // Volta pro Menu Principal
                // O motor já foi pausado na morte, então continua pausado
              }),
              child: Text(context.l10n.gameOver_menuPrincipal, style: const TextStyle(fontSize: 16, color: Palette.preto)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}