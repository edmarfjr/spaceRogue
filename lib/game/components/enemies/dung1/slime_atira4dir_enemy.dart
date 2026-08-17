import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import '../enemy.dart';
import '../enemy_mixins.dart'; 

class SlimeAtira4DirEnemy extends Enemy with JumpMovement, ShooterAttack {
  SlimeAtira4DirEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         size: Vector2(16, 16),
         hitboxSize: Vector2(12, 12), 
         spritePath: 'actors/slime.png', 
        animationData: SpriteAnimationData.sequenced(
           amount: 1, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 0.0, 
         health: 3,
         corClara: Palette.vermelho, // Um sapo azul para diferenciar do sapo verde normal!
         corEscura: Palette.roxoEsc, 
         shadowOffset: Vector2(0, 8),
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
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
    
    // Tempos do Salto: fica 1.5s no chão (dando tempo pra atirar)
    idleDuration = 1.5;  
    airDuration = 0.5;   

    // --- 2. PREPARA A ANIMAÇÃO DE TIRO ---
    // Como setupJumpAnimations já rodou, o setupAttack vai salvar a 'animIdle' 
    // como a animação base de movimento! Tudo se encaixa perfeitamente.
    setupAttackAnimation(
      frames: 3, 
      frameTime: 0.15, 
      textureSize: Vector2(16, 16), 
      texturePosition: Vector2(0, 16) 
    );
  }

  @override
  void movimento(double dt) {
    // 1. O mixin de Tiro atualiza os cronômetros internos dele.
    // Se o monstro já estiver na animação de ataque, ele trava a função (return) e não pula!
    if (updateAttack(dt, 2.5, _shootAt4Dir)) return;

    // 2. Lógica Mestra: Ele quer atirar? E ele ESTÁ NO CHÃO (idle)?
    if (wantsToShoot && jumpState == JumpState.idle) {
      triggerAttack();
      return; // Trava aqui também para ele não começar a agachar enquanto atira!
    }

    // 3. Se não está atirando, o cérebro de salto assume o controle do corpo!
    updateJumpMovement(
      dt, 
      playerTarget.absolutePosition, 
      mode: JumpMode.random, // Pula aleatoriamente
      jumpDistance: 16.0, 
      jumpHeight: 16.0,
    );
  }

  // Função chamada automaticamente pelo mixin de tiro quando a animação de cuspir acaba
  void _shootAt4Dir() {
    List<Vector2> directions = [
      Vector2(-1, -1), 
      Vector2(1, 1),  
      Vector2(-1, 1), 
      Vector2(1, -1),  
    ];
    for (var dir in directions) {
      shoot(dir);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // Se a SOMBRA bater na parede no meio do pulo, ele cai!
    if (other is WallBarrier || other is Obstacle) {
      if (!isPhysicsCollision(other)) return; 
      cancelJump(); 
    }
  }
}