import 'package:creatures_rogue/game/components/core/palette.dart';
import 'collectible.dart';
import '../player/player.dart';

/// Moeda da run. Ainda não tem onde gastar — a sala de loja é o passo
/// seguinte; por enquanto o valor só acumula em `Player.coins` e aparece na
/// Hud.
///
/// Gasta na loja (ver [ShopStand]).
class CoinPickup extends Collectible {
  final int valor;

  CoinPickup({required super.position, this.valor = 1})
      : super(
          spritePath: 'items/moeda.png',
          cor1: Palette.amarelo,
          cor2: Palette.laranja,
        );

  @override
  bool onCollect(Player player) {
    player.addCoins(valor);
    return true; // moeda sempre entra: não tem limite de slot nem teto útil
  }
}
