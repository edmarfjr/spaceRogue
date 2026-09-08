import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Cão Neutro — botão B. Late e empurra tudo ao redor, lentificando quem é
/// atingido. Pouco dano, controle é o ponto.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class LatidoFeroz extends Ability {
  final double coef;
  final double empurrao;
  final double lentidaoDuracao;

  const LatidoFeroz({
    this.coef = 0.2,
    this.empurrao = 60,
    this.lentidaoDuracao = 1.5,
  }) : super(
         nome: 'Latido Feroz',
         descricao: 'Empurra e lentifica tudo ao redor.',
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
        lentidaoDuracao: lentidaoDuracao,
        size: Vector2(40, 40),
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
