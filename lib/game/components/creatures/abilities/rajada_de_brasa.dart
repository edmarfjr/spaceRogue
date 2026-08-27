import 'dart:math';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Roedor de Fogo — botão A. Três projéteis em leque, dano alto e perto.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class RajadaDeBrasa extends Ability {
  final double coef;
  final double anguloLequeGraus;
  final double alcanceSegundos;

  const RajadaDeBrasa({this.coef = 0.67, this.anguloLequeGraus = 20, this.alcanceSegundos = 0.5})
      : super(nome: 'Rajada de Brasa', descricao: 'Três projéteis em leque, dano alto e curto alcance.', cooldown: 0.8);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final anguloRad = anguloLequeGraus * pi / 180;
    for (final offset in [-anguloRad, 0.0, anguloRad]) {
      final rotated = dir.clone()..rotate(offset);
      user.parent?.add(Projectile(
        position: user.position.clone(),
        direction: rotated,
        dmg: dano,
        lifeTime: alcanceSegundos,
        sprPath: 'projeteis/fogo2.png',
        cor1: Palette.vermelho,
        cor2: Palette.laranja,
        tipo: user.creatureData.tipo,
      ));
    }
  }
}
