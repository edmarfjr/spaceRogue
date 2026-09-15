import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Evolução de [BolhaProtetora] (ver `PIVOT_EVOLUCAO`): a bolha absorve DOIS
/// golpes em vez de um, dura mais, e o cooldown cai — o Sapo evoluído
/// consegue manter o escudo em pé quase o tempo todo.
class BolhaProtetoraEvo extends Ability {
  final int hits;
  final double duracao;

  const BolhaProtetoraEvo({this.hits = 2, this.duracao = 6.0})
    : super(
        nome: 'Bolha Reforçada',
        descricao: 'Escudo reforçado: absorve dois golpes e dura mais.',
        cooldown: 7.0,
        tipo: AbilityTipo.defesa,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    // Mesma chave da forma base: as duas são A bolha do Sapo, e a criatura
    // nunca tem as duas ao mesmo tempo (evolução troca a habilidade).
    user.adicionarEscudoTemporario(#bolhaProtetora, hits, duracao);
  }
}
