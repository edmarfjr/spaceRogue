import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tornado de Fogo — botão A. Cooldown baixo, dano alto, alcance
/// curto.
class SocoFlamejante extends Ability {
  final double dano;
  final double velocidade;
  final double alcanceSegundos;

  const SocoFlamejante({this.dano = 4, this.velocidade = 260, this.alcanceSegundos = 0.15})
      : super(nome: 'Soco Flamejante', cooldown: 0.4);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/soco.png',
      lifeTime: alcanceSegundos,
      cor1: Palette.vermelho,
      cor2: Palette.roxoEsc,
    ));
  }
}
