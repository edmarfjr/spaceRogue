import 'package:spacerogue/game/components/core/palette.dart';
import 'collectible.dart';
import '../player/player.dart';

// Herda de Collectible
class HeartPickup extends Collectible {
  HeartPickup({required super.position}) 
      // Passamos a imagem pro 'super' carregar!
      : super(spritePath: 'items/heartHalf.png',cor1: Palette.vermelho,cor2: Palette.roxoEsc);

  // Apenas implementamos a lógica do jogo
  @override
  bool onCollect(Player player) {
    // O método heal() do Player já retorna 'true' se curou ou 'false' se a vida estava cheia
    return player.heal(2); 
  }
}