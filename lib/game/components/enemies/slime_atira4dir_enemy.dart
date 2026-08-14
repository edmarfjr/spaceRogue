import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'enemy.dart'; 
import 'dart:math';

class SlimeAtira4DirEnemy extends Enemy {
  Vector2? targetPosition; 
  Vector2? _startPosition;
  
  final double tileSize = 16.0;
  final Random _random = Random();
  
  double pauseTimer = 0.0; 
  double pauseDuration = 0.4;

  double fireTimer = 0.0;
  double fireRate = 3.0;

  late final SpriteAnimation moveAnimation;
  late final SpriteAnimation attackAnimation;
  
  bool isAttacking = false;
  bool wantsToShoot = false;
  
  double attackTimer = 0.0;
  final int attackFrames = 3;           
  final double attackFrameTime = 0.15;  
  late final double attackDuration;     

  SlimeAtira4DirEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         // 1. Coloque aqui o nome do seu arquivo de spritesheet unificado!
         spritePath: 'actors/slime.png', 
         
         // 2. A classe base carrega automaticamente a primeira parte da imagem
         // (O movimento, que começa na posição 0,0 por padrão)
         animationData: SpriteAnimationData.sequenced(
           amount: 3, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 30.0,
         health: 3,
         corClara: Palette.vermelho, 
         corEscura: Palette.roxoEsc, 
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    moveAnimation = visual.animation!;
    attackDuration = (attackFrames-1) * attackFrameTime;

    final swappedImage = visual.animation!.frames.first.sprite.image;

    attackAnimation = SpriteAnimation.fromFrameData(
      swappedImage,
      SpriteAnimationData.sequenced(
        amount: attackFrames,
        stepTime: attackFrameTime,
        textureSize: Vector2(16, 16),
        texturePosition: Vector2(0, 16), 
        loop: false, 
      ),
    );
  }

  @override
  void movimento(double dt) {
    if (isAttacking) {
      attackTimer += dt;
      
      if (attackTimer >= attackDuration) {
        _fireProjectiles(); 
        
        isAttacking = false;
        attackTimer = 0.0;
        visual.animation = moveAnimation; 
        pauseTimer = 0.0; 
      }
      return; 
    }

    if (!wantsToShoot) {
      fireTimer += dt;
      if (fireTimer >= fireRate) {
        wantsToShoot = true;
        fireTimer = 0.0;
      }
    }

    if (targetPosition == null) {
      if (wantsToShoot) {
        isAttacking = true;
        wantsToShoot = false;
        
        visual.animation = attackAnimation;
        visual.animationTicker?.reset(); 
        return;
      }

      pauseTimer += dt;
      if (pauseTimer >= pauseDuration) {
        pauseTimer = 0.0;
        _pickNewTarget();
      }
      
    } else {
      Vector2 direction = targetPosition! - position;
      double distanceToMove = speed * dt;

      if (direction.length < distanceToMove) {
        position = targetPosition!.clone();
        targetPosition = null; 
      } else {
        position += direction.normalized() * distanceToMove;
        
        if (direction.x < 0 && !visual.isFlippedHorizontally) {
          visual.flipHorizontallyAroundCenter();
        } else if (direction.x > 0 && visual.isFlippedHorizontally) {
          visual.flipHorizontallyAroundCenter();
        }
      }
    }
  }

  void _fireProjectiles() {
    List<Vector2> directions = [
      Vector2(0, -1), // Cima
      Vector2(0, 1),  // Baixo
      Vector2(-1, 0), // Esquerda
      Vector2(1, 0),  // Direita
    ];
    for (var dir in directions) {
      shoot(dir);
    }
  }

  void _pickNewTarget() {
    List<Vector2> directions = [
      Vector2(1, 0),
      Vector2(-1, 0),
      Vector2(0, 1),
      Vector2(0, -1),
    ];
    
    Vector2 chosenDir = directions[_random.nextInt(4)];
    
    _startPosition = position.clone(); 
    targetPosition = position + (chosenDir * tileSize);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is WallBarrier || other is Obstacle || other is Enemy) {
      
      if (intersectionPoints.isNotEmpty) {
        double minX = intersectionPoints.first.x;
        double maxX = intersectionPoints.first.x;
        double minY = intersectionPoints.first.y;
        double maxY = intersectionPoints.first.y;

        for (var point in intersectionPoints) {
          if (point.x < minX) minX = point.x;
          if (point.x > maxX) maxX = point.x;
          if (point.y < minY) minY = point.y;
          if (point.y > maxY) maxY = point.y;
        }

        double overlapWidth = maxX - minX;
        double overlapHeight = maxY - minY;

        if (overlapWidth < 0.5 || overlapHeight < 0.5) {
          return; 
        }
      }

      if (_startPosition != null) {
        position = _startPosition!.clone();
      }
      targetPosition = null; 
      
    } else {
      super.onCollision(intersectionPoints, other);
    }
  }
}