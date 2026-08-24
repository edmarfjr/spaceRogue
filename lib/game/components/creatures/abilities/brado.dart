import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Urso de Planta — botão B. Um rugido que sacode a área ao redor e empurra
/// tudo pra longe. Pouco dano, muito peso.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class Brado extends Ability {
  final double coef;
  final double empurrao;

  const Brado({this.coef = 0.25, this.empurrao = 100})
      : super(nome: 'Brado', cooldown: 6.0, tipo: AbilityTipo.defesa);

  @override
  void execute(Player user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(ExplosionHitbox(
      position: user.position.clone(),
      dmg: dano,
      knockback: empurrao,
      size: Vector2(48, 48),
      tipo: user.creatureData.tipo,
    ));
  }
}
