import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Tubarão de Água — botão A. Mordida curta e pesada bem na frente, com
/// empurrão forte — o ponto não é só o dano, é afastar quem mordeu.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class Mordida extends Ability {
  final double coef;
  final double alcance;
  final double empurrao;

  const Mordida({this.coef = 1.1, this.alcance = 16, this.empurrao = 60})
      : super(nome: 'Mordida', descricao: 'Mordida curta e pesada com empurrão forte.', cooldown: 0.3, custoEnergia: 3.5);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
          owner: user,
          position:user.position.clone() + dir.normalized() * alcance,
          direction: dir,
          speed: 0,
          dmg: dano,
          lifeTime: 0.4,
          sprPath: 'projeteis/bite.png',
          cor1: Palette.bege,
          cor2: Palette.royal,
          tipo: user.creatureData.tipo,
        ));
    user.parent?.add(ExplosionHitbox(
      position: user.position.clone() + dir.normalized() * alcance,
      dmg: dano/4,
      size: Vector2(20, 20),
      knockback: empurrao,
      tipo: user.creatureData.tipo,
    ));
  }
}
