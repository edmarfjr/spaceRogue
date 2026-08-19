import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tartaruga de Planta — botão A. Projétil lento e pesado, empurra bastante.
class CuspeVenenoso extends Ability {
  final double dano;
  final double velocidade;

  const CuspeVenenoso({this.dano = 4, this.velocidade = 90})
      : super(nome: 'Cuspe de Semente', cooldown: 1.4);

  @override
  void execute(Player user, Vector2 dir) {
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
