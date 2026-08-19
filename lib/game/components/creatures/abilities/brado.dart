import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Urso de Planta — botão B. Um rugido que sacode a área ao redor e empurra
/// tudo pra longe. Pouco dano, muito peso.
class Brado extends Ability {
  final double dano;
  final double empurrao;

  const Brado({this.dano = 1, this.empurrao = 100})
      : super(nome: 'Brado', cooldown: 6.0);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(ExplosionHitbox(
      position: user.position.clone(),
      dmg: dano,
      knockback: empurrao,
      size: Vector2(48, 48),
    ));
  }
}
