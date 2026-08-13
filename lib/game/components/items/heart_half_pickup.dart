import 'collectible.dart';
import '../player/player.dart';

// Herda de Collectible
class HeartHalfPickup extends Collectible {
  HeartHalfPickup({required super.position}) 
      // Passamos a imagem pro 'super' carregar!
      : super(spritePath: 'items/heartHalf.png');

  // Apenas implementamos a lógica do jogo
  @override
  bool onCollect(Player player) {
    // O método heal() do Player já retorna 'true' se curou ou 'false' se a vida estava cheia
    return player.heal(1); 
  }
}