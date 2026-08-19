import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Ave de Eletricidade — botão A. Cooldown baixíssimo, dano baixo, alcance
/// curto. O DPS vem do volume de disparos, não do golpe individual.
class BicoEletrico extends Ability {
  final double dano;
  final double velocidade;
  final double alcanceSegundos;

  const BicoEletrico({this.dano = 1, this.velocidade = 260, this.alcanceSegundos = 0.25})
      : super(nome: 'Bico Elétrico', cooldown: 0.25);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/proj2.png',
      lifeTime: alcanceSegundos,
      cor1: Palette.amarelo,
      cor2: Palette.laranja,
    ));
  }
}
