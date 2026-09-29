import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Evolução de [LatidoFeroz]: o latido vira UIVO — além de empurrar e
/// lentificar, atordoa.
///
/// Atordoar em vez de somar dano porque o Doguin já bate forte no botão A: o
/// papel do botão B dele é comprar espaço, e paralisar por um instante compra
/// muito mais espaço do que um número maior. O raio cresce junto, senão o
/// atordoamento só alcançaria quem já estava colado.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class LatidoFerozEvo extends Ability {
  final double coef;
  final double empurrao;
  final double lentidaoDuracao;
  final double atordoamento;
  final double raio;

  const LatidoFerozEvo({
    this.coef = 0.4,
    this.empurrao = 80,
    this.lentidaoDuracao = 2.5,
    this.atordoamento = 0.8,
    this.raio = 56,
  }) : super(
         nome: 'Uivo',
         descricao: 'Empurra, lentifica e atordoa tudo ao redor.',
         cooldown: 5.0,
         tipo: AbilityTipo.defesa,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(
      ExplosionHitbox(
        position: user.position.clone(),
        dmg: dano,
        knockback: empurrao,
        stunDuration: atordoamento,
        lentidaoDuracao: lentidaoDuracao,
        size: Vector2.all(raio),
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
