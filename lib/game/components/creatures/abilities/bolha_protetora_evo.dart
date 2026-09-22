import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'bolha_protetora.dart';

/// Evolução de [BolhaProtetora] (ver `PIVOT_EVOLUCAO`): a bolha absorve DOIS
/// golpes em vez de um, dura mais, e o cooldown cai — o Sapo evoluído
/// consegue manter o escudo em pé quase o tempo todo.
///
/// O estouro também é mais forte, mas acontece com menos frequência: a bolha
/// só arrebenta no SEGUNDO golpe, então o empurrão vale mais por ser mais
/// raro.
class BolhaProtetoraEvo extends Ability {
  final int hits;
  final double duracao;

  static const double kbEstouro = 120.0;
  static const double raioEstouro = 48.0;

  const BolhaProtetoraEvo({this.hits = 2, this.duracao = 6.0})
    : super(
        nome: 'Bolha Reforçada',
        descricao: 'Escudo reforçado: absorve dois golpes e repele mais forte.',
        cooldown: 4.0,
        tipo: AbilityTipo.defesa,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    // Mesma chave da forma base: as duas são A bolha do Sapo, e a criatura
    // nunca tem as duas ao mesmo tempo (evolução troca a habilidade).
    user.adicionarEscudoTemporario(
      #bolhaProtetora,
      hits,
      duracao,
      aoEstourar: () =>
          BolhaProtetora.estourar(user, kbEstouro, raioEstouro),
    );
  }
}
