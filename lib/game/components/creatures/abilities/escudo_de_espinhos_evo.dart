import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Evolução de `EscudoDeEspinhos`: mais golpes absorvidos, janela mais longa e
/// retaliação bem mais forte.
///
/// Só números — o mecanismo é o mesmo da forma base, e ele vive fora daqui: a
/// habilidade só escreve `retaliaEspinhos`/`retaliaDano`/`retaliaStunDuration`
/// e quem lê é o `Player.takeDamage`, no ramo que consome a bolha de escudo.
///
/// AVISO: essa retaliação passou a funcionar muito recentemente — os três
/// campos `retalia*` ficavam sem nenhum leitor, então a forma BASE nunca foi
/// jogada com ela ativa. Se o saldo aqui parecer estranho, confira a base
/// primeiro.
class EscudoDeEspinhosEvo extends Ability {
  final int golpes;
  final double duracao;
  final double coefDano;
  final double duracaoStun;

  const EscudoDeEspinhosEvo({
    this.golpes = 4,
    this.duracao = 5.0,
    this.coefDano = 1.0,
    this.duracaoStun = 1.5,
  }) : super(
         nome: 'Escudo de Espinhos+',
         descricao:
             'Absorve mais golpes e revida cada um com uma descarga forte.',
         cooldown: 7.0,
         tipo: AbilityTipo.defesa,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.adicionarEscudoTemporario(#escudoDeEspinhos, golpes, duracao);

    user.retaliaDano = user.creatureData.stats.ataque * coefDano;
    user.retaliaStunDuration = duracaoStun;
    user.aplicarEfeito(
      #retaliaEspinhos,
      duracao,
      aoIniciar: () => user.retaliaEspinhos = true,
      aoTerminar: () => user.retaliaEspinhos = false,
    );
  }
}
