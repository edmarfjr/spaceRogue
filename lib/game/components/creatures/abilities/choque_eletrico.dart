import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Grilo Eletrico — botão A. Projetil que se divide.
class ChoqueEletrico extends Ability {
  final double dano;
  final double velocidade;
  final double kbForce;
  final double alcanceSegundos;

  const ChoqueEletrico({this.dano = 1, this.velocidade = 90, this.kbForce = 10, this.alcanceSegundos = 0.5})
      : super(nome: 'Choque Eletrico', cooldown: 0.4);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      kbForce: kbForce,
      lifeTime: alcanceSegundos,
      sprPath: 'projeteis/raio.png',
      cor1: Palette.amarelo,
      cor2: Palette.laranja,
      fragmentos:3
    ));
  }
}
