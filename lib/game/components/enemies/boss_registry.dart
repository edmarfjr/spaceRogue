import 'dart:math';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'creatures/ave_eletrica_boss_enemy.dart';
import 'creatures/bomba_fogo_boss_enemy.dart';
import 'creatures/caranguejo_ermitao_boss_enemy.dart';
import 'creatures/cobra_agua_boss_enemy.dart';
import 'creatures/grilo_eletrico_boss_enemy.dart';
import 'creatures/ourico_eletrico_boss_enemy.dart';
import 'creatures/roedor_fogo_boss_enemy.dart';
import 'creatures/sapo_agua_boss_enemy.dart';
import 'creatures/slime_planta_boss_enemy.dart';
import 'creatures/tartaruga_planta_boss_enemy.dart';
import 'creatures/tornado_fogo_boss_enemy.dart';
import 'creatures/urso_planta_boss_enemy.dart';
import 'enemy.dart';

typedef BossBuilder = Enemy Function(Vector2 position, Player playerTarget);

class BossOption {
  /// Criatura que este boss libera pra jogar quando é derrotado.
  final String creatureId;

  final BossBuilder builder;

  const BossOption({
    required this.creatureId,
    required this.builder,
  });

  /// Nome mostrado na barra de vida e no reveal. Derivado da criatura em vez de
  /// guardado aqui: os nomes das criaturas ainda estão sendo definidos, e
  /// duplicar faria a barra do boss divergir do resto do jogo.
  String get nome => CreatureRegistry.byId(creatureId).nome.toUpperCase();
}

/// Quais bosses existem e qual deles cai na run atual.
///
/// Escopo do projeto: toda criatura tem as três formas (jogável, inimigo comum
/// e boss), então esta lista termina cobrindo o elenco inteiro — sem isso,
/// criatura sem boss ficaria sem via de desbloqueio.
class BossRegistry {
  static final List<BossOption> all = [
    BossOption(
      creatureId: 'bomba_fogo',
      builder: (pos, plr) => BombaFogoBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'slime_planta',
      builder: (pos, plr) => SlimePlantaBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'tartaruga_planta',
      builder: (pos, plr) => TartarugaPlantaBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'cobra_agua',
      builder: (pos, plr) => CobraAguaBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'tornado_fogo',
      builder: (pos, plr) => TornadoFogoBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'urso_planta',
      builder: (pos, plr) => UrsoPlantaBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'ave_eletrica',
      builder: (pos, plr) => AveEletricaBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'roedor_fogo',
      builder: (pos, plr) => RoedorFogoBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'grilo_eletrico',
      builder: (pos, plr) => GriloEletricoBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'sapo_agua',
      builder: (pos, plr) => SapoAguaBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'ourico_eletrico',
      builder: (pos, plr) => OuricoEletricoBossEnemy(position: pos, playerTarget: plr),
    ),
    BossOption(
      creatureId: 'caranguejo_fogo',
      builder: (pos, plr) => CaranguejoErmitaoBossEnemy(position: pos, playerTarget: plr),
    ),
  ];

  /// Sorteia um boss cuja criatura o jogador AINDA NÃO tem.
  ///
  /// Sortear entre os já derrotados desperdiçaria a run inteira (você lutaria
  /// por um prêmio que já está na mão), então a poça só contém pendências.
  /// Retorna null quando não há mais nada a conquistar — aí o andar de boss
  /// volta a ser um andar comum.
  static BossOption? sortearPendente(Random random) {
    final pendentes = all
        .where((b) => !CreatureProgress.instance.isUnlocked(b.creatureId))
        .toList();

    if (pendentes.isEmpty) return null;
    return pendentes[random.nextInt(pendentes.length)];
  }
}
