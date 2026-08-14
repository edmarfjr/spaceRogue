import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'enemy.dart';

class ShooterEnemy extends Enemy {
  double fireTimer = 0.0;
  final double fireRate = 1.5; // Tempo entre os tiros (1.5 segundos)
  
  final double optimalDistance = 80.0; // Distância que ele tenta manter de você
  final double tolerance = 15.0; // "Folga" para ele não ficar tremendo no lugar

  ShooterEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         spritePath: 'actors/slime.png',
         animationData: SpriteAnimationData.sequenced(
           amount: 3, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 25.0, // Ele anda devagarzinho
         health: 3,
         corClara: Palette.vermelho, // Vai nascer vermelho pra você saber que atira!
       );

  @override
  void movimento(double dt) {
    // 1. CÁLCULO DE DISTÂNCIA
    Vector2 directionToPlayer = playerTarget.position - position;
    double distance = directionToPlayer.length;

    Vector2 moveDirection = Vector2.zero();

    // 2. DECISÃO DE MOVIMENTO
    if (distance > optimalDistance + tolerance) {
      // Muito longe: Anda na direção do jogador
      moveDirection = directionToPlayer.normalized();
    } else if (distance < optimalDistance - tolerance) {
      // Muito perto: FOGE na direção oposta ao jogador!
      moveDirection = -directionToPlayer.normalized();
    }

    // 3. APLICAÇÃO DO MOVIMENTO
    if (!moveDirection.isZero()) {
      position += moveDirection * speed * dt;

      // Vira o rostinho na direção que está andando
      if (moveDirection.x < 0 && !visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      } else if (moveDirection.x > 0 && visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      }
    }

    // 4. LÓGICA DE TIRO
    fireTimer += dt;
    if (fireTimer >= fireRate) {
      fireTimer = 0.0;
      Vector2 direction = (playerTarget.position - position).normalized();
      shoot(direction);
    }
  }

  
}