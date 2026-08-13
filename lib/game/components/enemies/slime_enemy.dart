import 'package:flame/components.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'enemy.dart'; 
import 'dart:math';

class SlimeEnemy extends Enemy {
  Vector2? targetPosition; 
  final double tileSize = 16.0;
  final Random _random = Random();
  
  double pauseTimer = 0.0; 
  final double pauseDuration = 0.4;

  SlimeEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         spritePath: 'actors/slime.png',
         animationData: SpriteAnimationData.sequenced(
           amount: 3, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 30.0,
         health: 3,
         corClara: Palette.verde, 
         corEscura: Palette.verdeEsc, 
       );

  @override
  void movimento(double dt) {
    if (targetPosition == null) {
      // ESTADO 1: Parado, pensando pra onde ir
      pauseTimer += dt;
      if (pauseTimer >= pauseDuration) {
        pauseTimer = 0.0;
        _pickNewTarget();
      }
    } else {
      // ESTADO 2: Andando até o bloco alvo
      Vector2 direction = targetPosition! - position;
      double distanceToMove = speed * dt;

      if (direction.length < distanceToMove) {
        // Chegou exatamente no bloco! Crava a posição e volta a pensar
        position = targetPosition!.clone();
        targetPosition = null; 
      } else {
        // Continua andando
        position += direction.normalized() * distanceToMove;
        
        // Espelha o sprite se andar pra esquerda/direita
        if (direction.x < 0 && !visual.isFlippedHorizontally) {
          visual.flipHorizontallyAroundCenter();
        } else if (direction.x > 0 && visual.isFlippedHorizontally) {
          visual.flipHorizontallyAroundCenter();
        }
      }
    }
  }

  void _pickNewTarget() {
    // Opções rígidas: Direita, Esquerda, Baixo, Cima
    List directions = [
      Vector2(1, 0),
      Vector2(-1, 0),
      Vector2(0, 1),
      Vector2(0, -1),
    ];
    
    Vector2 chosenDir = directions[_random.nextInt(4)];
    
    // Define o alvo exato a 16 pixels de distância
    targetPosition = position + (chosenDir * tileSize);
  }

  // O GRANDE TRUQUE: Sobrescrever a colisão da superclasse
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other); // Deixa o BaseEnemy empurrar ele pra trás
    
    // Se ele tentou andar pra uma parede ou pedra e bateu, ele desiste do caminho!
    if (other is WallBarrier || other is Obstacle) {
       targetPosition = null; // Volta a pensar em outra direção imediatamente
    }
  }
}