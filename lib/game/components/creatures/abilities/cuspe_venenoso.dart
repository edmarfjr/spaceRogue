import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Slime de Planta — botão A. Projétil lento que envenena.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class CuspeVenenoso extends Ability {
  final double coef;
  final double velocidade;

  const CuspeVenenoso({this.coef = 1.0, this.velocidade = 90})
      : super(nome: 'Cuspe Venenoso', cooldown: 1.4);

  @override
  void execute(Player user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/proj1.png',
      cor1: Palette.verde,
      cor2: Palette.verdeEsc,
      isPoison: true,
      poisonCount: 3,
    ));
  }
}
