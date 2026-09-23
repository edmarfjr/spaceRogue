import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Evolução de [Mordida]: duas dentadas em vez de uma, a segunda mais à
/// frente.
///
/// O que limitava a base não era o dano, era o ALCANCE: uma caixa de 20 px
/// colada no focinho obriga o Tubarão a encostar, e o empurrão dele mesmo
/// joga a presa pra fora do alcance da mordida seguinte. A segunda caixa,
/// mais adiante, cobre justamente onde o primeiro empurrão deixa o inimigo.
///
/// As duas saem no mesmo quadro, e não em sequência com atraso, porque
/// `Ability` não tem como agendar nada sem `Future` — e um `Future` solto
/// continuaria rodando depois de uma troca de criatura.
class MordidaEvo extends Ability {
  final double coef;
  final double alcance;
  final double alcanceLonge;
  final double empurrao;

  const MordidaEvo({
    this.coef = 0.8,
    this.alcance = 10,
    this.alcanceLonge = 22,
    this.empurrao = 70,
  }) : super(
         nome: 'Dentada Dupla',
         descricao: 'Duas mordidas em sequência, a segunda alcançando mais longe.',
         cooldown: 1.3,
         custoEnergia: 4.0,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    // `coef` menor que o da base (0,8 contra 1,1) porque são DUAS caixas: no
    // alvo pego pelas duas o total sobe pra 1,6 do ataque, e quem só encosta
    // na de fora leva menos que a mordida antiga. Acertar de perto continua
    // sendo melhor.
    final dano = user.creatureData.stats.ataque * coef;
    final frente = dir.normalized();

    for (final distancia in [alcance, alcanceLonge]) {
      user.parent?.add(
        ExplosionHitbox(
          position: user.position.clone() + frente * distancia,
          dmg: dano,
          size: Vector2(20, 20),
          knockback: empurrao,
          tipo: user.creatureData.tipo,
        ),
      );
    }
  }
}
