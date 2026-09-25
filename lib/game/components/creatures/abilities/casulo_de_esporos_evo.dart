import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'casulo_de_esporos.dart';

/// Evolução de [CasuloDeEsporos]: absorve DOIS golpes e a nuvem do estouro é
/// maior e mais duradoura.
///
/// O estouro continua saindo só no ÚLTIMO golpe absorvido, não em cada um. É
/// o que mantém o casulo sendo defesa: se soltasse nuvem a cada golpe, ele
/// viraria um gerador de área que premia apanhar, e o Cogumelo já tem o botão
/// A pra plantar nuvem por escolha.
class CasuloDeEsporosEvo extends Ability {
  final int golpes;
  final double duracao;
  final double duracaoNuvem;
  final double coefNuvem;
  final int ticksVeneno;
  final double raioNuvem;

  const CasuloDeEsporosEvo({
    this.golpes = 2,
    this.duracao = 6.0,
    this.duracaoNuvem = 6.0,
    this.coefNuvem = 0.7,
    this.ticksVeneno = 4,
    this.raioNuvem = 20,
  }) : super(
         nome: 'Casulo Denso',
         descricao:
             'Absorve dois golpes e estoura numa nuvem de esporos maior.',
         cooldown: 6.0,
         tipo: AbilityTipo.defesa,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    // Mesma chave da forma base: as duas são O casulo do Cogumelo, e a
    // criatura nunca tem as duas ao mesmo tempo (evoluir troca a habilidade).
    user.adicionarEscudoTemporario(
      #casuloDeEsporos,
      golpes,
      duracao,
      aoEstourar: () => CasuloDeEsporos.soltarNuvem(
        user,
        coefNuvem: coefNuvem,
        ticksVeneno: ticksVeneno,
        raio: raioNuvem,
        duracao: duracaoNuvem,
      ),
    );
  }
}
