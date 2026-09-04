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
        cooldown: 6.0,
        tipo: AbilityTipo.defesa,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.shieldHits = hits;
    user.shieldVisualActive = true;

    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted && user.shieldHits > 0) {
        user.shieldHits = 0;
        user.shieldVisualActive = false;
      }
    });
  }
}
