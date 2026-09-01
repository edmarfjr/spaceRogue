import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'collectible.dart';
import '../player/player.dart';

class BombPickup extends Collectible {
  BombPickup({required super.position})
      : super(spritePath: 'items/bomb.png',cor1: Palette.indigo,cor2: Palette.azulEsc);

  @override
  bool onCollect(Player player) {
    player.addBomb(1);
    player.parent?.add(TextEffect(
      text: player.game.buildContext!.l10n.effect_maisBomba,
      position: player.position.clone() + Vector2(0, -player.size.y / 2 - 4),
      color: Palette.branco,
    ));
    return true; // Bombas sempre podem ser pegas
  }
}