import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

class BicoEletricoEvo extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;
  final double duracaoStun;
  final double kbForce;

  const BicoEletricoEvo({
    this.coef = 2.0,
    this.velocidade = 260,
    this.alcanceSegundos = 0.25,
    this.duracaoStun = 0.6,
    this.kbForce = 7,
  }) : super(nome: 'Bico Elétrico+', cooldown: 0.15, custoEnergia: 1.0);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final anguloGraus = Random().nextDouble() * 20 - 10; // Random angle between -10 and 10 degrees
    final anguloRad = anguloGraus * pi / 180;
    final rotated = dir.clone()..rotate(anguloRad);
    double stunChance = Random().nextDouble();
    double stunDur = 0;
    if (stunChance <= 0.2){
      stunDur = duracaoStun;
    }
    user.parent?.add(
      Projectile(
        owner: user,
        position: user.position.clone(),
        direction: rotated,
        speed: velocidade,
        dmg: dano,
        kbForce: kbForce,
        sprPath: 'projeteis/proj2.png',
        lifeTime: alcanceSegundos,
        stunDuration: stunDur,
        cor1: Palette.amarelo,
        cor2: Palette.laranja,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
