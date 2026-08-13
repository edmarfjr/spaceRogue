import 'package:flame/components.dart';
import 'collectible.dart';
import '../player/player.dart';

class BombPickup extends Collectible {
  BombPickup({required Vector2 position}) 
      : super(position: position, spritePath: 'items/bomb.png');

  @override
  bool onCollect(Player player) {
    player.addBomb(1);
    return true; // Bombas sempre podem ser pegas
  }
}