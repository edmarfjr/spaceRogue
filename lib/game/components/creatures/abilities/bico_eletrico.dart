import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Ave de Eletricidade — botão A. Cooldown baixíssimo, dano baixo, alcance
/// curto. O DPS vem do volume de disparos, não do golpe individual.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class BicoEletrico extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;
  final double kbForce;

  const BicoEletrico({this.coef = 1.0, this.velocidade = 260, this.alcanceSegundos = 0.25, this.kbForce = 5})
      : super(nome: 'Bico Elétrico', descricao: 'bicadas elétricas velozes.', cooldown: 0.2, custoEnergia: 1.5);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final anguloGraus = Random().nextDouble() * 30 - 15; // Random angle between -15 and 15 degrees
    final anguloRad = anguloGraus * pi / 180;
    final rotated = dir.clone()..rotate(anguloRad);
    user.parent?.add(Projectile(
      owner: user,
      position: user.position.clone(),
      direction: rotated,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/proj2.png',
      lifeTime: alcanceSegundos,
      kbForce:kbForce,
      cor1: Palette.amarelo,
      cor2: Palette.laranja,
      tipo: user.creatureData.tipo,
    ));
  }
}
