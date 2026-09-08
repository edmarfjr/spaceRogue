import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Bomba de Fogo — botão A. Deixa uma bomba no chão.
class DeixarBomba extends Ability {
  const DeixarBomba(): super(nome: 'Deixar Bomba', descricao: 'Deixa uma bomba no chão — consome o estoque do treinador.', cooldown: 1, target: AbilityTarget.plrDir);

  /// Sem bomba no contador do treinador, o botão não dispara e o cooldown
  /// não gira — habilidade inteira depende do recurso (ver PIVOT_TREINADOR.md
  /// §3.2), diferente de Esquiva Bomba, que também tem uma metade evasiva.
  @override
  bool canExecute(AbilityUser user) => user.bombsAmount > 0;

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.placeBomb(user.lockedAb1Direction);
  }
}
