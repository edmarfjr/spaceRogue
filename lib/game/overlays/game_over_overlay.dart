import 'package:flutter/material.dart';
import 'package:spacerogue/game/space_rogue_game.dart';

class GameOverMenu extends StatelessWidget {
  final SpacerogueGame game;
  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(color: Colors.red, fontSize: 50, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                // 1. Remove a tela de Game Over
                game.overlays.remove('GameOver');
                // 2. Chama a função de limpar e resetar variáveis
                game.resetGame();
                // 3. Volta o botão de Pause e descongela o jogo
                game.overlays.add('Hud');
                game.resumeEngine();
              },
              child: const Text("RESTART", style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              onPressed: () {
                game.overlays.remove('GameOver');
                game.resetGame();
                game.overlays.add('MainMenu'); // Volta pro Menu Principal
                // O motor já foi pausado na morte, então continua pausado
              },
              child: const Text("MENU PRINCIPAL", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}