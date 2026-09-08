import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Urso de Planta — botão B. Um rugido que sacode a área ao redor e empurra
/// tudo pra longe. Pouco dano, muito peso.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class BradoEvo extends Ability {
  final double coef;
  final double empurrao;

  const BradoEvo({this.coef = 1, this.empurrao = 150})
    : super(
        nome: 'Brado',
        descricao: 'Rugido que empurra tudo ao redor; pouco dano, muito peso.',
        cooldown: 6.0,
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
        size: Vector2(64, 64),
        tipo: user.creatureData.tipo,
        paraliseDuration: 2.0,
      ),
    );
  }
}
