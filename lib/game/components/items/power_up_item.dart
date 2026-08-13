import 'collectible.dart'; // Sua classe base de coletáveis
import '../player/player.dart';

enum PowerUpType { speedUp, fireRateUp, damageUp, hpUp }

class PowerUpItem extends Collectible {
  final PowerUpType type;

  PowerUpItem({
    required super.position,
    required this.type,
  }) : super(
         spritePath: 'items/heart.png', 
       );

  @override
  bool onCollect(Player player) {
    // Aplica o upgrade permanente baseado no tipo
    switch (type) {
      case PowerUpType.speedUp:
        // player.maxSpeed += 20.0; // Aumenta a velocidade do player
        break;
      case PowerUpType.fireRateUp:
        // player.shootCooldown -= 0.05; // Atira mais rápido
        break;
      case PowerUpType.damageUp:
        // player.damage += 1; // Dá mais dano
        break;
      case PowerUpType.hpUp:
        player.maxHealth +=2;
        player.currentHealth +=2;

        break;
    }

    print("Item coletado: $type");
    return true; // Retorna true para sumir do chão
  }
}