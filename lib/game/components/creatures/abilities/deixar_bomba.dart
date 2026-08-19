import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

/// Bomba de Fogo — botão A. Deixa uma bomba no chão.
class DeixarBomba extends Ability {
  const DeixarBomba(): super(nome: 'Deixar Bomba', cooldown: 1, target: AbilityTarget.plrDir);

  @override
  void execute(Player user, Vector2 dir) {
    user.placeBomb(user.lockedAb1Direction);
  }
}
