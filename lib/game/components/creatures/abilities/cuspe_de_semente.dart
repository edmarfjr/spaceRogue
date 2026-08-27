import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tartaruga de Planta — botão A. Projétil lento e pesado, empurra bastante.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class CuspeDeSemente extends Ability {
  final double coef;
  final double velocidade;
  final double kbForce;

  const CuspeDeSemente({this.coef = 1.33, this.velocidade = 90, this.kbForce = 30})
      : super(nome: 'Cuspe de Semente', cooldown: 1.4);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      kbForce: kbForce,
      sprPath: 'projeteis/proj1.png',
      cor1: Palette.verde,
      cor2: Palette.verdeEsc,
      tipo: user.creatureData.tipo,
    ));
  }
}
