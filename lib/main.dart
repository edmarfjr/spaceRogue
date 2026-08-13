import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/space_rogue_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();
  
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GameContainer(),
  ));
}

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State createState() => _GameContainerState();
}

class _GameContainerState extends State {
  // Guarda a instância do jogo atual
  late SpacerogueGame game;
  bool showGameOver = false;

  Key gameKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      showGameOver = false;
      
      // Gera uma chave totalmente nova! O Flutter vai ser obrigado a resetar tudo.
      gameKey = UniqueKey(); 
      
      // Cria o jogo novo passando a função de Game Over direto no construtor
      game = SpacerogueGame(
        onGameOver: () {
          setState(() {
            showGameOver = true;
          });
          game.pauseEngine(); // Pausa os zumbis e a física
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: Stack(
        children: [
          // O Jogo rodando
          GameWidget(
            key: gameKey, 
            game: game,
          ),
          
          // Tela de Game Over por cima
          if (showGameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "GAME OVER",
                      style: TextStyle(color: Colors.red, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _startNewGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: const Text("RESTART", style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}