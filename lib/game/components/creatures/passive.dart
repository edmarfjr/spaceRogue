import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/player/player.dart';

/// Comportamento sempre-ligado de UMA criatura, que vale enquanto ela estiver
/// em campo.
///
/// Não confundir com as passivas de aposentadoria (`ItemEfeito`): aquelas são
/// do JOGADOR e sobrevivem à troca de criatura; estas são da CRIATURA e morrem
/// quando ela sai de campo. É a mesma distinção de posse que fez `ItemEfeito`
/// existir — e é por isso que as duas coisas não podem ser a mesma classe.
///
/// ENXUTA de propósito. A versão anterior carregava `aoEsquivar`,
/// `direcaoEsquivaOverride`, `dodgeCooldownMult` e `dodgeDistanceMult`, todos
/// sem call site depois de o `Player.dodge()` embutido ser desligado e a
/// esquiva virar habilidade 2 de cada criatura. Gancho declarado sem ponto de
/// chamada foi exatamente o que fez as passivas de aposentadoria nascerem
/// ligadas no lugar errado — então aqui só entra gancho que já é chamado.
/// Precisando de outro, adicione o gancho E o call site na mesma mudança.
abstract class Passive {
  /// Nome curto, mostrado nos cards de criatura.
  final String nome;

  const Passive({required this.nome});

  /// Todo quadro, a partir de `Player.update`.
  void aoAtualizar(Player player, double dt) {}

  /// Toda esquiva (habilidade 2 do tipo `esquiva`), com a direção resolvida.
  /// Call site em `Player.dispararAbility2`, o mesmo do gancho equivalente do
  /// `ItemEfeito` — e NÃO no `dodge()` embutido, que está desligado.
  void aoEsquivar(Player player, Vector2 direcao) {}

  /// No início de `Player.takeDamage`, depois do i-frame e da redução de dano,
  /// mas ANTES de qualquer escudo consumir o golpe — dispara mesmo que o dano
  /// acabe inteiramente absorvido.
  void aoTentarTomarDano(Player player, double amount) {}
}
