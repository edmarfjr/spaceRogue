import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Evolução de [InvestidaDaLanca]: investida mais longa, e o golpe do fim
/// PARALISA além de empurrar.
///
/// O que NÃO mudou é o essencial: o trajeto continua sem acertar ninguém, só
/// o pouso machuca. É o que separa esta habilidade das disparadas que
/// atropelam no caminho — quem quer dano tem que escolher onde parar, não só
/// por onde passar.
///
/// A paralisia é o prêmio por acertar esse ponto: fechar distância com i-
/// frames e ainda prender o alvo é o que permite ao Leão evoluído emendar a
/// investida na estocada seguinte.
class InvestidaDaLancaEvo extends Ability {
  final double distancia;
  final double duracao;
  final double coef;
  final double empurrao;
  final double duracaoParalise;

  const InvestidaDaLancaEvo({
    this.distancia = 52,
    this.duracao = 0.2,
    this.coef = 2.8,
    this.empurrao = 90,
    this.duracaoParalise = 1.2,
  }) : super(
         nome: 'Investida Trovejante',
         descricao:
             'Dash com i-frames; o golpe do final empurra e paralisa o alvo.',
         cooldown: 4.0,
         target: AbilityTarget.plrDir,
         tipo: AbilityTipo.esquiva,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.grantInvulnerability(duracao);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(
      MoveByEffect(
        // `dashOffsetLivre` é o que impede a investida de enfiar o Leão dentro
        // da parede — com a distância maior daqui isso passou a importar mais.
        user.dashOffsetLivre(dir, distancia),
        EffectController(duration: duracao),
        onComplete: () {
          user.parent?.add(
            ExplosionHitbox(
              position: user.position.clone(),
              dmg: dano,
              knockback: empurrao,
              paraliseDuration: duracaoParalise,
              size: Vector2(30, 30),
              tipo: user.creatureData.tipo,
            ),
          );
        },
      ),
    );
  }
}
