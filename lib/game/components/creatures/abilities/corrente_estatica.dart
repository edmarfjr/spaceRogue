import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/creatures/ability.dart';
import 'package:spacerogue/game/components/player/player.dart';
import 'package:spacerogue/game/components/projeteis/explosion_hitbox.dart';

/// Ave de Eletricidade — botão B. Área ao redor do próprio corpo: dano baixo
/// mais atordoamento. É a habilidade de quebrar cerco de quem luta colado.
class CorrenteEstatica extends Ability {
  final double dano;
  final double duracaoStun;

  const CorrenteEstatica({this.dano = 1, this.duracaoStun = 1.5})
      : super(nome: 'Corrente Estática', cooldown: 5.0);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(ExplosionHitbox(
      position: user.position.clone(),
      dmgPlr: 0,
      dmgEnemy: dano.round(),
      isStun: true,
      stunDuration: duracaoStun,
      cor1: Palette.amarelo,
      cor2: Palette.laranja,
    ));
  }
}
