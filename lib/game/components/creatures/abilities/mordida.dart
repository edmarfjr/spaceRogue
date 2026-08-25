import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Tubarão de Água — botão A. Mordida curta e pesada bem na frente, com
/// empurrão forte — o ponto não é só o dano, é afastar quem mordeu.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class Mordida extends Ability {
  final double coef;
  final double alcance;
  final double empurrao;

  const Mordida({this.coef = 1.1, this.alcance = 10, this.empurrao = 60})
      : super(nome: 'Mordida', cooldown: 1.3);

  @override
  void execute(Player user, Vector2 dir) {
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
