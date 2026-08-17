import 'package:flutter/material.dart';
import 'package:spacerogue/game/space_rogue_game.dart';

class MainMenuOverlay extends StatelessWidget {
  final SpacerogueGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SPACE ROGUE',
              style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                // Remove o menu, adiciona o HUD de pause e despausa o motor
                game.overlays.remove('MainMenu');
                game.overlays.add('Hud');
                game.resumeEngine();
              },
              child: const Text('JOGAR', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}