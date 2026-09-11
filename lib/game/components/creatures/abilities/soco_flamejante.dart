import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tornado de Fogo — botão A. Cooldown baixo, dano alto, alcance
/// curto.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class SocoFlamejante extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  const SocoFlamejante({this.coef = 1.0, this.velocidade = 260, this.alcanceSegundos = 0.2})
      : super(nome: 'Soco Flamejante', descricao: 'Cooldown baixo, dano alto, alcance curto.', cooldown: 0.4);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    Vector2 dirOff = Vector2(0,0); 
    int rand = Random().nextInt(8) - 4;
    if (dir.x == 0 ){
      dirOff = Vector2(rand.toDouble(), 0);
    } else {
      dirOff = Vector2(0, rand.toDouble());
    }
    user.parent?.add(Projectile(
      owner: user,
      position: user.position.clone() + dirOff,
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/soco.png',
      lifeTime: alcanceSegundos,
      cor1: Palette.vermelho,
      cor2: Palette.roxoEsc,
      tipo: user.creatureData.tipo,
    ));
  }
}
