import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/overlays/console_overlay.dart';
import 'package:spacerogue/game/overlays/game_over_overlay.dart';
import 'package:spacerogue/game/overlays/main_menu_overlay.dart';
import 'package:spacerogue/game/overlays/pause_overlay.dart';
import 'package:spacerogue/game/space_rogue_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF2C2C2C),
        body: GameWidget<SpacerogueGame>(
          game: SpacerogueGame(), // Não precisa mais passar onGameOver no construtor
          overlayBuilderMap: {
            'MainMenu': (context, game) => MainMenuOverlay(game: game),
            'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
            'Hud': (context, game) => HudOverlay(game: game),
            'GameOver': (context, game) => GameOverMenu(game: game), // <--- REGISTRO NOVO
          },
          initialActiveOverlays: const ['MainMenu'], // Começa no Menu
        ),
      ),
    ),
  );
}

class GameOverOverlay {
}