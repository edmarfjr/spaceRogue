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
  static final List<SpawnOption> _pool = [
    SpawnOption(CreatureRegistry.aveEletrica, 20),     // frágil, comum
    SpawnOption(CreatureRegistry.roedorFogo, 16),      // frágil, comum
    SpawnOption(CreatureRegistry.griloEletrico, 14),   // frágil, comum
    SpawnOption(CreatureRegistry.sapoAgua, 12),        // médio
    SpawnOption(CreatureRegistry.slimePlanta, 9),      // médio, suja a arena
    SpawnOption(CreatureRegistry.tartarugaPlanta, 8),  // tanque, menos comum
    SpawnOption(CreatureRegistry.bombaFogo, 6),        // ameaça alta, raro
    SpawnOption(CreatureRegistry.cobraAgua, 5),        // ameaça alta, raro
    SpawnOption(CreatureRegistry.tornadoFogo, 4),      // ameaça alta, muito raro
    SpawnOption(CreatureRegistry.ursoPlanta, 3),       // ameaça alta, muito raro
  ];

  static Enemy getRandomEnemy(Vector2 position, Player player) {
    int totalWeight = 0;
    for (final option in _pool) {
      totalWeight += option.weight;
    }

    int roll = _random.nextInt(totalWeight);
    int currentWeight = 0;

    for (final option in _pool) {
      currentWeight += option.weight;
      if (roll < currentWeight) {
        return option.creature.enemyBuilder!(position, player);
      }
    }

    return _pool.first.creature.enemyBuilder!(position, player);
  }
}
