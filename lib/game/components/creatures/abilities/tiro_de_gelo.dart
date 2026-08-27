import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Pinguem de Agua — botão A. Projétil que estilhaça.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class TiroDeGelo extends Ability {
  final double coef;

  const TiroDeGelo({this.coef = 1.33})
      : super(nome: 'Tiro de Gelo', cooldown: 1.0);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      dmg: dano,
      sprPath: 'projeteis/proj1.png',
      cor1: Palette.azul,
      cor2: Palette.indigo,
      tipo: user.creatureData.tipo,
      estilhaca: true,
    ));
  }
}
