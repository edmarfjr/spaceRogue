import 'dart:math';
import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/creatures/ability.dart';
import 'package:spacerogue/game/components/player/player.dart';
import 'package:spacerogue/game/components/projeteis/projectile.dart';

/// Roedor de Fogo — botão A. Três projéteis em leque, dano alto e perto.
class RajadaDeBrasa extends Ability {
  final double dano;
  final double anguloLequeGraus;
  final double alcanceSegundos;

  const RajadaDeBrasa({this.dano = 2, this.anguloLequeGraus = 20, this.alcanceSegundos = 0.5})
      : super(nome: 'Rajada de Brasa', cooldown: 0.8);

  @override
  void execute(Player user, Vector2 dir) {
    final anguloRad = anguloLequeGraus * pi / 180;
    for (final offset in [-anguloRad, 0.0, anguloRad]) {
      final rotated = dir.clone()..rotate(offset);
      user.parent?.add(Projectile(
        position: user.position.clone(),
        direction: rotated,
        dmg: dano,
        lifeTime: alcanceSegundos,
        sprPath: 'projeteis/fogo.png',
        cor1: Palette.vermelho,
        cor2: Palette.laranja,
      ));
    }
  }
}
