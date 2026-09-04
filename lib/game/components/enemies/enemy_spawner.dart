import 'dart:math';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'enemy.dart';
import '../player/player.dart';

class SpawnOption {
  final CreatureData creature;
  final int weight; // Quanto maior, mais comum. (ex: 10 é comum, 1 é raro)

  const SpawnOption(this.creature, this.weight);
}

class EnemySpawner {
  static final Random _random = Random();

  /// Peso por ameaça: os fracos e rápidos aparecem sempre, os pesados são
  /// raros. Sem isso, uma dungeon de 12 salas pode encher de Urso.
  static final List<List<SpawnOption>> _pool = [
    [
      SpawnOption(CreatureRegistry.aveEletrica, 20),     // frágil, comum 20
      SpawnOption(CreatureRegistry.roedorFogo, 20),      // frágil, comum 16
      SpawnOption(CreatureRegistry.griloEletrico, 20),   // frágil, comum 14
      SpawnOption(CreatureRegistry.sapoAgua, 20),        // médio 12
      SpawnOption(CreatureRegistry.slimePlanta, 20),      // médio, suja a arena 9
      SpawnOption(CreatureRegistry.pinguimAgua, 20),      // tanque, menos comum8
      SpawnOption(CreatureRegistry.tartarugaPlanta, 20),  // tanque, menos comum8
      SpawnOption(CreatureRegistry.ouricoEletrico, 20),   // tanque, menos comum7
      SpawnOption(CreatureRegistry.caranguejoErmitao, 20),// tanque, menos comum7
      SpawnOption(CreatureRegistry.tocoPlanta, 20),       // tanque parado, menos comum7
      SpawnOption(CreatureRegistry.bombaFogo, 20),        // ameaça alta, raro6
      SpawnOption(CreatureRegistry.cobraAgua, 20),        // ameaça alta, raro5
      SpawnOption(CreatureRegistry.leaoEletrico, 20),     // ameaça alta, raro5
      SpawnOption(CreatureRegistry.tornadoFogo, 20),      // ameaça alta, muito raro4
      SpawnOption(CreatureRegistry.ursoPlanta, 20),       // ameaça alta, muito raro3
      SpawnOption(CreatureRegistry.tubaraoAgua, 20),      // ameaça alta, muito raro3
    ],
    [
      SpawnOption(CreatureRegistry.roedorFogo, 20),
      SpawnOption(CreatureRegistry.tartarugaPlanta, 20),
      SpawnOption(CreatureRegistry.sapoAgua, 20), 
      SpawnOption(CreatureRegistry.aveEletrica, 20),
    ]
  ];

  static Enemy getRandomEnemy(Vector2 position, Player player, int dungeon) {
    int totalWeight = 0;
    for (final option in _pool[dungeon]) {
      totalWeight += option.weight;
    }

    int roll = _random.nextInt(totalWeight);
    int currentWeight = 0;

    for (final option in _pool[dungeon]) {
      currentWeight += option.weight;
      if (roll < currentWeight) {
        return option.creature.enemyBuilder!(position, player);
      }
    }

    return _pool[dungeon].first.creature.enemyBuilder!(position, player);
  }
}
