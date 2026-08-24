import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class PauseMenuOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const PauseMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.preto.withOpacity(0.7),
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
              const Text('JOGO PAUSADO', style: TextStyle(color: Palette.preto, fontSize: 32)),
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
                onPressed: () {
                  game.overlays.remove('PauseMenu');
                  game.resumeEngine();
                },
                child: const Text(' CONTINUAR ', style: TextStyle(fontSize: 20, color: Palette.preto)),
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
                onPressed: () {
                  game.overlays.remove('PauseMenu');
                  game.overlays.remove('Hud');
                  game.overlays.add('MainMenu');
                  // Chama a sua função de limpar/reiniciar a fase!
                  //game.resetGame(); 
                },
                child: const Text(' SAIR PARA O MENU ', style: TextStyle(fontSize: 20, color: Palette.preto)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}