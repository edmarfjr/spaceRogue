import 'package:flame/components.dart';
import 'package:spacerogue/game/components/creatures/ability.dart';
import 'package:spacerogue/game/components/player/player.dart';
import 'package:spacerogue/game/components/projeteis/explosion_hitbox.dart';

/// Urso de Planta — botão A. Soco curto e pesado bem na frente do focinho.
class MegaSoco extends Ability {
  final int dano;
  final double alcance;
  final double empurrao;

  const MegaSoco({this.dano = 5, this.alcance = 12, this.empurrao = 50})
      : super(nome: 'Mega Soco', cooldown: 1.3);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(ExplosionHitbox(
      position: user.position.clone() + dir.normalized() * alcance,
      dmgPlr: 0,
      dmgEnemy: dano,
      size: Vector2(20, 20),
      knockback: empurrao,
    ));
  }
}
