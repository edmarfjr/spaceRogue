import 'dart:math';

import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de `TiroDeGelo`: em vez de um projétil, um LEQUE de três, e cada
/// um deles lentifica quem acerta.
///
/// O upgrade é cobertura mais controle, não dano bruto: o Pinguim é lento
/// (speed 40), então o que ele ganha em evoluir é a capacidade de segurar o
/// inimigo no lugar em vez de correr dele.
class TiroDeGeloEvo extends Ability {
  final double coef;
  final double lentidaoDuracao;
  final double lentidaoFator;

  /// Abertura do leque, em graus, entre um tiro e o do meio.
  final double aberturaGraus;

  const TiroDeGeloEvo({
    this.coef = 1.1,
    this.lentidaoDuracao = 1.5,
    this.lentidaoFator = 0.5,
    this.aberturaGraus = 14,
  }) : super(
         nome: 'Tiro de Gelo+',
         descricao: 'Leque de três projéteis que estilhaçam e lentificam.',
         cooldown: 1.0,
         custoEnergia: 3.0,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final abertura = aberturaGraus * pi / 180;

    for (final desvio in [-abertura, 0.0, abertura]) {
      user.parent?.add(
        Projectile(
          owner: user,
          position: user.position.clone(),
          direction: dir.clone()..rotate(desvio),
          dmg: dano,
          sprPath: 'projeteis/proj1.png',
          cor1: Palette.azul,
          cor2: Palette.indigo,
          tipo: user.creatureData.tipo,
          lentidaoDuracao: lentidaoDuracao,
          lentidaoFator: lentidaoFator,
          estilhaca: true,
          // Só o tiro do meio toca som: três `play` no mesmo quadro caem no
          // throttle do `GameAudio` de qualquer forma, e pedir três pra ouvir
          // um só gasta voz do pool à toa.
          playSfx: desvio == 0.0,
        ),
      );
    }
  }
}
