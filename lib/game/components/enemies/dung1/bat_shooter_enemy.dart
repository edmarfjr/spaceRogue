import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import '../enemy.dart'; 
import '../enemy_mixins.dart'; 

class BatShooterEnemy extends Enemy with WanderMovement, ShooterAttack {
  
  BatShooterEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         size: Vector2(16, 16),
         hitboxSize: Vector2(12, 12),
         spritePath: 'actors/bat.png', // Mude para seu sprite
         animationData: SpriteAnimationData.sequenced(
           amount: 2, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 30.0, 
         health: 3,
         corClara: Palette.vermelho, 
         corEscura: Palette.marromEsc,  
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(frames: 3, frameTime: 0.15, textureSize: Vector2(16, 16), texturePosition: Vector2(32, 0));
  }

  @override
  void movimento(double dt) {
    // 1. Atualiza o ataque. Se estiver atirando, o código trava aqui.
    if (updateAttack(dt, 3.0, _shootAtPlayer)) return;

    // 2. Lógica de Proximidade: Quer atirar? Está perto?
    if (wantsToShoot) {
      double distanceToPlayer = (playerTarget.absolutePosition - absolutePosition).length;
      
      if (distanceToPlayer <= 64.0) { // Distância de ativação em pixels
        triggerAttack();
        return; 
      }
    }

    // 3. Se não atirou, vaga normalmente
    updateWanderMovement(dt);
  }

  void _shootAtPlayer() {
    Vector2 direction = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direction);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is WallBarrier || other is Obstacle) cancelWander();
  }
}