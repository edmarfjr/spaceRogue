import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy_mixins.dart';
import '../enemy.dart'; 

class PlantaShooterEnemy extends Enemy with ShooterAttack{
  late final SpriteAnimation idleAnimation;
  
  final double fireRate = 2.5; // Tempo de espera entre os ataques (em segundos)
  
  final int attackFrames = 4;           // Quantidade de quadros da animação de ataque
  final double attackFrameTime = 0.15;  

  PlantaShooterEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         size: Vector2(16, 16),
         hitboxSize: Vector2(12, 16),
         
         // Substitua pelo nome do arquivo da sua planta
         spritePath: 'actors/spitPlant.png', 
         
         // Configuração da animação de Idle (parada)
         animationData: SpriteAnimationData.sequenced(
           amount: 2, 
           stepTime: 0.3, 
           textureSize: Vector2(16, 16),
         ),
         speed: 0.0, // Velocidade zero!
         health: 3,
         corClara: Palette.burgundy,    // Ajuste para as cores da sua paleta
         corEscura: Palette.verdeEsc, 
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(frames: 4, frameTime: 0.15, textureSize: Vector2(16, 16), texturePosition: Vector2(16, 0));
  }

  @override
  void applyKnockback(Vector2 sourcePosition, double force) {} // Imóvel
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, 2.5, _shootAtPlayer)) return;

    if (wantsToShoot) {
      triggerAttack();
    }
  }

  void _shootAtPlayer() {
    Vector2 direction = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direction);
  }

}