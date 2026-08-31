import 'dart:async';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/overlays/boss_reveal_overlay.dart';
import 'package:creatures_rogue/game/overlays/capture_swap_overlay.dart';
import 'package:creatures_rogue/game/overlays/console_overlay.dart';
import 'package:creatures_rogue/game/overlays/creature_select_overlay.dart';
import 'package:creatures_rogue/game/overlays/game_over_overlay.dart';
import 'package:creatures_rogue/game/overlays/intro_overlay.dart';
import 'package:creatures_rogue/game/overlays/main_menu_overlay.dart';
import 'package:creatures_rogue/game/overlays/pause_overlay.dart';
import 'package:creatures_rogue/game/overlays/settings_overlay.dart';
import 'package:creatures_rogue/game/game_settings.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';

bool get isDesktopPlatform {
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return false;
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CreatureProgress.instance.load();
  await GameSettings.instance.load();
  // Sem `await`: os .wav são pequenos, mas carregar áudio não pode ser o que
  // atrasa a primeira tela. `GameAudio.play()` já é seguro de chamar antes
  // disso terminar — só fica mudo até o pool ficar pronto.
  unawaited(GameAudio.instance.preload());
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();

  //if (!isDesktopPlatform) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
 // }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'pixelFont', // Define a fonte padrão para todo o app
        //primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        backgroundColor: Palette.cinza,
        body: GameWidget<CreaturesRogueGame>(
          game: CreaturesRogueGame(
            // Esquema escolhido na última sessão (ver GameSettings).
            controlScheme: GameSettings.instance.controlScheme,
          ),
          overlayBuilderMap: {
            'MainMenu': (context, game) => MainMenuOverlay(game: game),
            'Settings': (context, game) => SettingsOverlay(game: game),
            'Intro': (context, game) => IntroOverlay(game: game),
            'CreatureSelect': (context, game) => CreatureSelectOverlay(game: game),
            'BossReveal': (context, game) => BossRevealOverlay(game: game),
            'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
            'CaptureSwap': (context, game) => CaptureSwapOverlay(game: game),
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
