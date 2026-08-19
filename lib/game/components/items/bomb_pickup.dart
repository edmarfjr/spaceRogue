import 'package:creatures_rogue/game/components/core/palette.dart';
import 'collectible.dart';
import '../player/player.dart';

class BombPickup extends Collectible {
  BombPickup({required super.position}) 
      : super(spritePath: 'items/bomb.png',cor1: Palette.indigo,cor2: Palette.azulEsc);

  @override
  bool onCollect(Player player) {
    player.addBomb(1);
    return true; // Bombas sempre podem ser pegas
  }
}