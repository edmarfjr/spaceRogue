import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class HudOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IconButton(
          icon: const Icon(Icons.pause_circle_outline, color: Colors.white, size: 40),
          onPressed: () {
            game.pauseEngine(); // Congela o jogo inteiro!
            game.overlays.add('PauseMenu');
          },
        ),
      ),
    );
  }
}