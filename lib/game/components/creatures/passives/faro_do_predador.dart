import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/passive.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

/// Doguin evoluído — o crítico arranca um naco de vida do alvo e devolve pra
/// você.
///
/// Preso ao crítico, e não a todo acerto, por conta bem concreta: a Mordida
/// Faminta sai a cada 0,8s sustentada (`energiaRegenAtraso` mais
/// `custoEnergia / energiaRegen`, que é o que manda — não o cooldown). Curando
/// em todo acerto seriam ~1,1 de vida por segundo numa barra de 6, ou seja a
/// barra cheia a cada 5 segundos, e o dano deixaria de ser recurso. Com
/// `critBonus: 10` (15% no total) o crítico sai a cada ~5,3s e a cura cai pra
/// ~0,19 por segundo.
///
/// De quebra, `critChanceUp`, Sangue Frio e Gatilho Frio viram itens de build
/// pra esta criatura especificamente: quem investe em crítico investe em
/// sustento.
class FaroDoPredador extends Passive {
  const FaroDoPredador() : super(nome: 'Faro do Predador');

  /// Em unidades de vida, onde um coração inteiro vale 2 (ver `HeartPickup`).
  /// 1 = meio coração.
  static const int cura = 1;

  @override
  void aoCritar(Player player, Enemy alvo) {
    // `heal` devolve false com a vida cheia — e também com o item Jejum na
    // mochila, que desliga a cura. Os dois casos são no-op aqui, de propósito:
    // o item amaldiçoado tem que vencer a passiva, senão "não cura mais" seria
    // mentira.
    if (!player.heal(cura)) return;
    player.parent?.add(
      TextEffect.dano(
        cura.toDouble(),
        position: player.position.clone() + Vector2(0, -player.size.y / 2 - 4),
        color: Palette.verde,
      ),
    );
  }
}
