import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [Rabanada]: a cauda varre os DOIS lados — um golpe pra frente
/// e outro pra trás, no mesmo disparo.
///
/// Pra trás, e não dois em leque à frente: o Layfishy é das criaturas mais
/// lentas e se arrasta, então virar pra encarar quem chega pelas costas custa
/// caro. O verbo novo é cobrir a retaguarda, não acertar mais o mesmo alvo —
/// os dois golpes quase nunca pegam o mesmo inimigo, e por isso o `coef` de
/// cada um fica igual ao da forma base.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class RabanadaEvo extends Ability {
  final double coef;
  final double velocidade;

  const RabanadaEvo({this.coef = 1.5, this.velocidade = 160})
    : super(
        nome: 'Rabanada Dupla',
        descricao: 'Golpe de cauda pra frente e pra trás ao mesmo tempo.',
        cooldown: 0.4,
        // Mais caro que a base (2.5): saem dois golpes por disparo.
        custoEnergia: 3.0,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final frente = dir.length == 0 ? Vector2(0, 1) : dir.normalized();

    for (final sentido in [frente, -frente]) {
      user.parent?.add(
        Projectile(
          owner: user,
          position: user.position.clone(),
          direction: sentido,
          speed: velocidade,
          lifeTime: 0.5,
          dmg: dano,
          radius: 8,
          sprPath: 'projeteis/proj1.png',
          cor1: user.creatureData.corClara,
          cor2: user.creatureData.corEscura,
          tipo: user.creatureData.tipo,
        ),
      );
    }
  }
}
