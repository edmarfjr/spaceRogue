import 'dart:math';
import 'package:flame/components.dart';
import 'package:spacerogue/game/components/enemies/dung1/planta_shooter.dart';
import 'dung1/fly_enemy.dart';
import 'dung1/fly_explode_enemy.dart';
import 'enemy.dart';
import 'dung1/slime_atira4dir_enemy.dart';
import 'dung1/slime_enemy.dart';
import 'dung1/et_chaser_enemy.dart';
import '../player/player.dart';

typedef EnemyBuilder = Enemy Function(Vector2 position, Player playerTarget);

class SpawnOption {
  final EnemyBuilder builder;
  final int weight; // Quanto maior, mais comum. (ex: 10 é comum, 1 é raro)

  SpawnOption(this.builder, this.weight);
}

class EnemySpawner {
  static final Random _random = Random();

  static final List _pool = [
    SpawnOption((pos, player) => SlimeEnemy(position: pos, playerTarget: player), 10), 
    SpawnOption((pos, player) => EtChaserEnemy(position: pos, playerTarget: player), 5),   
    SpawnOption((pos, player) => PlantaShooterEnemy(position: pos, playerTarget: player), 5), 
    SpawnOption((pos, player) => SlimeAtira4DirEnemy(position: pos, playerTarget: player), 5),
    SpawnOption((pos, player) => FlyEnemy(position: pos, playerTarget: player), 20),  
    SpawnOption((pos, player) => FlyExplodeEnemy(position: pos, playerTarget: player), 10),
  ];

  static Enemy getRandomEnemy(Vector2 position, Player player) {
    int totalWeight = 0;
    for (var option in _pool) {
      totalWeight += option.weight as int;
    }

    int roll = _random.nextInt(totalWeight);
    int currentWeight = 0;

    for (var option in _pool) {
      currentWeight += option.weight as int;
      if (roll < currentWeight) {
        return option.builder(position, player);
      }
    }
    
    return _pool.first.builder(position, player); 
  }
}