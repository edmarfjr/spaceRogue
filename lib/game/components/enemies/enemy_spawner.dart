import 'dart:math';
import 'package:flame/components.dart';
import 'enemy.dart';
import 'slime_atira4dir_enemy.dart';
import 'slime_enemy.dart';
import 'et_enemy.dart';
import '../player/player.dart';

// Assinatura de um construtor de inimigo: recebe a Posição e o Alvo, retorna um BaseEnemy.
typedef EnemyBuilder = Enemy Function(Vector2 position, Player playerTarget);

class SpawnOption {
  final EnemyBuilder builder;
  final int weight; // Quanto maior, mais comum. (ex: 10 é comum, 1 é raro)

  SpawnOption(this.builder, this.weight);
}

class EnemySpawner {
  static final Random _random = Random();

  static final List _pool = [
    
    SpawnOption((pos, player) => SlimeEnemy(position: pos, playerTarget: player), 10), // Peso 10 (Muito comum)
    SpawnOption((pos, player) => EtEnemy(position: pos, playerTarget: player), 5),   // Peso 5 (Metade da chance)
    SpawnOption((pos, player) => SlimeAtira4DirEnemy(position: pos, playerTarget: player), 5), 
  ];

  // Sorteia UM inimigo da pool com base no peso (Weighted Random)
  static Enemy getRandomEnemy(Vector2 position, Player player) {
    int totalWeight = 0;
    for (var option in _pool) {
      totalWeight += option.weight as int;
    }

    // Rola um dado de 0 até o total do peso (ex: 15)
    int roll = _random.nextInt(totalWeight);
    int currentWeight = 0;

    for (var option in _pool) {
      currentWeight += option.weight as int;
      if (roll < currentWeight) {
        // Retorna a execução do construtor daquele inimigo!
        return option.builder(position, player);
      }
    }
    
    // Fallback de segurança (nunca deve chegar aqui, mas o Dart exige)
    return _pool.first.builder(position, player); 
  }
}