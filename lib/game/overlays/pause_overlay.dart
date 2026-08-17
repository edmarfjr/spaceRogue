import 'package:flutter/material.dart';
import 'package:spacerogue/game/space_rogue_game.dart';

class PauseMenuOverlay extends StatelessWidget {
  final SpacerogueGame game;
  const PauseMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('JOGO PAUSADO', style: TextStyle(color: Colors.white, fontSize: 32)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('PauseMenu');
                  game.resumeEngine();
                },
                child: const Text('CONTINUAR', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  game.overlays.remove('PauseMenu');
                  game.overlays.remove('Hud');
                  game.overlays.add('MainMenu');
                  // Chama a sua função de limpar/reiniciar a fase!
                  //game.resetGame(); 
                },
                child: const Text('SAIR PARA O MENU', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}