import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

class ExplosaoVenenosa extends Ability {
  final double dano;
  final double empurrao;

  const ExplosaoVenenosa({this.dano = 1, this.empurrao = 50})
      : super(nome: 'Explosao Venenosa', cooldown: 6.0);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(ExplosionHitbox(
      position: user.position.clone(),
      dmg: dano,
      knockback: empurrao,
      size: Vector2(24, 24),
      cor1: Palette.verde,
      cor2: Palette.verdeEsc,
    ));

    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: 0,
      dmg: 0,
      kbForce: 0,
      sprPath: 'projeteis/bolaGrande.png',
      cor1: Palette.verde,
      cor2: Palette.verdeEsc,
      isPoison: true,
      atravessa: 10,
      size: Vector2(24, 24),
      lifeTime: 3,
      radius: 12
    ));
  }
}
