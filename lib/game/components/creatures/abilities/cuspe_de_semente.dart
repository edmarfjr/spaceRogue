import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tartaruga de Planta — botão A. Projétil lento e pesado, empurra bastante.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class CuspeDeSemente extends Ability {
  final double coef;
  final double velocidade;
  final double kbForce;

  const CuspeDeSemente({this.coef = 1.5, this.velocidade = 90, this.kbForce = 40})
      : super(nome: 'Cuspe de Semente', descricao: 'Dispara uma semente pesada, pode prender inimigos ao chão.', cooldown: 0.3, custoEnergia: 3.5);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    int paralChance = Random().nextInt(100);

    user.parent?.add(Projectile(
      owner: user,
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      kbForce: kbForce,
      paralizDuracao: paralChance <= 15? 2.0 : 0,
      sprPath: 'projeteis/proj1.png',
      cor1: Palette.verde,
      cor2: Palette.verdeEsc,
      tipo: user.creatureData.tipo,
    ));
  }
}
