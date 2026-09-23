import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [BaforadaDeCinzas]: a baforada vai mais longe e, ao se
/// desfazer, ESPALHA brasas em volta.
///
/// O alcance curto era o preço do kit do Caranguejo, e a evolução não o anula
/// de vez — ela paga de outro jeito. A nuvem continua morrendo depressa, mas
/// `fragmentos` faz cada morte virar três brasas em direções sorteadas (ver
/// `Projectile.onDestroy`), que herdam a queimadura. Na prática o sopro deixa
/// de ser uma linha e vira uma área suja logo à frente.
///
/// `lifeTime` maior que o da forma base também estica os fragmentos, porque
/// eles nascem com o mesmo prazo do pai.
class BaforadaDeCinzasEvo extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;
  final int ticksQueimadura;
  final int fragmentos;

  const BaforadaDeCinzasEvo({
    this.coef = 0.7,
    this.velocidade = 80,
    this.alcanceSegundos = 0.45,
    this.ticksQueimadura = 3,
    this.fragmentos = 3,
  }) : super(
         nome: 'Baforada de Brasas',
         descricao:
             'Sopro de cinzas que se desfaz em brasas espalhadas, todas queimando.',
         cooldown: 1.6,
         custoEnergia: 4.5,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(
      Projectile(
        owner: user,
        position: user.position.clone(),
        direction: dir,
        speed: velocidade,
        dmg: dano,
        lifeTime: alcanceSegundos,
        sprPath: 'projeteis/nuvemP.png',
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
        tipo: user.creatureData.tipo,
        dotKind: DotKind.queimadura,
        dotTicks: ticksQueimadura,
        fragmentos: fragmentos,
        radius: 9,
      ),
    );
  }
}
