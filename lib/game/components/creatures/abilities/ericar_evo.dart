import 'dart:math';

import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de `Ericar`. A base já dispara em todas as direções, então o que
/// evolui não é a cobertura: são espinhos que ATRAVESSAM e PARALISAM.
///
/// Combina com o Ouriço ser o mais lento do elenco (speed 28): ele não escapa
/// de nada, então evoluir significa imobilizar em vez de fugir.
class EricarEvo extends Ability {
  final double coef;
  final int quantidade;
  final double velocidade;

  /// Quantos inimigos cada espinho atravessa antes de sumir.
  final int atravessa;

  final double paralizDuracao;

  const EricarEvo({
    this.coef = 1.1,
    this.quantidade = 12,
    this.velocidade = 125,
    this.atravessa = 2,
    this.paralizDuracao = 0.6,
  }) : super(
         nome: 'Eriçar+',
         descricao: 'Espinhos em todas as direções que perfuram e paralisam.',
         cooldown: 1.5,
         custoEnergia: 4.5,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;

    for (int i = 0; i < quantidade; i++) {
      final angulo = (2 * pi / quantidade) * i;
      user.parent?.add(
        Projectile(
          owner: user,
          position: user.position.clone(),
          direction: Vector2(cos(angulo), sin(angulo)),
          speed: velocidade,
          dmg: dano,
          lifeTime: 0.9,
          sprPath: 'projeteis/raio.png',
          cor1: user.creatureData.corClara,
          cor2: user.creatureData.corEscura,
          tipo: user.creatureData.tipo,
          atravessa: atravessa,
          paralizDuracao: paralizDuracao,
          // Doze espinhos no mesmo quadro: só o primeiro pede som. Os outros
          // onze cairiam no throttle do `GameAudio` e só gastariam voz do
          // pool.
          playSfx: i == 0,
        ),
      );
    }
  }
}
