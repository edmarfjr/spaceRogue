import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/golpe_de_tentaculo.dart';

/// Calamarin — botão A. Um tentáculo varre um arco de 120° à frente, como o
/// balanço de uma espada. Único golpe em ARCO do elenco: os outros corpo a
/// corpo são projéteis curtos em linha.
///
/// O lado alterna a cada golpe (de cima pra baixo, depois de baixo pra cima),
/// que é o que faz a sequência parecer um combo e não o mesmo golpe repetido.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class Tentaculada extends Ability {
  final double coef;
  final double alcance;

  const Tentaculada({this.coef = 1.6, this.alcance = 22})
    : super(
        nome: 'Tentaculada',
        descricao: 'Um tentáculo varre um arco à frente.',
        cooldown: 0.4,
        custoEnergia: 2.5,
      );

  /// Estático porque a habilidade é `const` e não guarda estado. Dividido
  /// entre todo mundo que usa a Tentaculada — na prática só o jogador, já que
  /// o inimigo monta o golpe direto.
  static double _sentido = 1.0;

  @override
  void execute(AbilityUser user, Vector2 dir) {
    _sentido = -_sentido;
    user.parent?.add(
      GolpeDeTentaculo(
        dono: user,
        direcao: dir,
        arco: 2 * pi / 3,
        sentido: _sentido,
        duracao: 0.15,
        alcance: alcance,
        dano: user.creatureData.stats.ataque * coef,
        tipo: user.creatureData.tipo,
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
      ),
    );
  }
}
