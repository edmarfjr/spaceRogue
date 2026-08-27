import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Urso de Planta — botão A. Soco curto e pesado bem na frente do focinho.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class MegaSoco extends Ability {
  final double coef;
  final double alcance;
  final double empurrao;

  const MegaSoco({this.coef = 1.25, this.alcance = 12, this.empurrao = 50})
      : super(nome: 'Mega Soco', cooldown: 1.3);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(ExplosionHitbox(
      position: user.position.clone() + dir.normalized() * alcance,
      dmg: dano,
      size: Vector2(20, 20),
      knockback: empurrao,
      tipo: user.creatureData.tipo,
    ));
  }
}
