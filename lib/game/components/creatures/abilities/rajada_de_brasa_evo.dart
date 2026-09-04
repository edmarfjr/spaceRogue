import 'dart:math';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [RajadaDeBrasa] (ver `PIVOT_EVOLUCAO`): o leque ganha mais dois
/// projéteis (5 em vez de 3) — o Roedor evoluído cobre um arco bem mais largo
/// na mesma rajada.
class RajadaDeBrasaEvo extends Ability {
  final double coef;
  final double anguloLequeGraus;
  final double alcanceSegundos;

  const RajadaDeBrasaEvo({
    this.coef = 0.7,
    this.anguloLequeGraus = 18,
    this.alcanceSegundos = 0.5,
  }) : super(nome: 'Rajada de Brasa+', cooldown: 0.8);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final anguloRad = anguloLequeGraus * pi / 180;
    final offsets = [-anguloRad * 2, -anguloRad, 0.0, anguloRad, anguloRad * 2];
    for (final offset in offsets) {
      final rotated = dir.clone()..rotate(offset);
      user.parent?.add(
        Projectile(
          owner: user,
          position: user.position.clone(),
          direction: rotated,
          dmg: dano,
          lifeTime: alcanceSegundos,
          sprPath: 'projeteis/fogo2.png',
          cor1: Palette.vermelho,
          cor2: Palette.laranja,
          tipo: user.creatureData.tipo,
        ),
      );
    }
  }
}
