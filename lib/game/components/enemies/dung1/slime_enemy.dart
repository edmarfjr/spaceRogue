import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import '../enemy.dart'; 
import '../enemy_mixins.dart'; 

class SlimeEnemy extends Enemy with JumpMovement {
  
  SlimeEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         size: Vector2(16, 16),
         hitboxSize: Vector2(12, 12),
         spritePath: 'actors/slime.png', // Substitua pela sua spritesheet
         
         // A animação base é genérica, nós vamos sobrescrever ela no onLoad
         animationData: SpriteAnimationData.sequenced(
           amount: 1, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 30.0,
         health: 3,
         corClara: Palette.verde, 
         corEscura: Palette.verdeEsc, 
         shadowOffset: Vector2(0, 8),
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Pega a imagem base com as cores já aplicadas pela classe Enemy
    final swappedImage = visual.animation!.frames.first.sprite.image;
    
    // 1. Animação Parado (Exemplo: Linha 0 da spritesheet, 2 frames)
    SpriteAnimation animIdle = SpriteAnimation.fromFrameData(
      swappedImage,
      SpriteAnimationData.sequenced(amount: 1, stepTime: 0.4, textureSize: Vector2(16, 16), texturePosition: Vector2(0, 0)),
    );

    // 2. Animação Agachando/Preparando (Exemplo: Linha 1 da spritesheet, 3 frames)
    double prepStepTime = 0.15;
    int prepFrames = 3;
    SpriteAnimation animPrep = SpriteAnimation.fromFrameData(
      swappedImage,
      SpriteAnimationData.sequenced(amount: prepFrames, stepTime: prepStepTime, textureSize: Vector2(16, 16), texturePosition: Vector2(0, 0), loop: false),
    );

    // 3. Animação Voando (Exemplo: Linha 2 da spritesheet, 1 frame)
    SpriteAnimation animAir = SpriteAnimation.fromFrameData(
      swappedImage,
      SpriteAnimationData.sequenced(amount: 1, stepTime: 1.0, textureSize: Vector2(16, 16), texturePosition: Vector2(48, 0)),
    );

    // Configura o Cérebro passando as 3 animações recortadas
    setupJumpAnimations(
      idle: animIdle,
      prep: animPrep,
      air: animAir,
      prepTime: (prepFrames-1) * prepStepTime, // O tempo total da animação 2!
    );
    
    // Você pode ajustar o ritmo do pulo aqui:
    airDuration = 0.45;  // Fica quase meio segundo voando pelo ar
    idleDuration = 1.2;  // Fica mais de um segundo parado no chão
  }

  @override
  void movimento(double dt) {
    // Ordena que o Cérebro pule sempre na direção atual do jogador,
    // rasgando o ar com a incrível velocidade de 150 pixels/segundo!
    updateJumpMovement(
      dt, 
      playerTarget.absolutePosition,
      mode: JumpMode.random, 
      jumpDistance: 16.0,
      jumpHeight: 16.0,
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is WallBarrier || other is Obstacle) {
      
      // PERGUNTA MÁGICA: A sombra bateu? Ou ele passou voando por cima?
      if (!isPhysicsCollision(other)) return; 
      
      cancelJump(); // Só aborta se a sombra (pés) bateu direto numa parede alta!
    }
  }
}