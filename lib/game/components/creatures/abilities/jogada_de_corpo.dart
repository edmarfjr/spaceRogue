import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Cobra de Água — botão B. Salta na direção apontada com a mesma curva de
/// altura/esticada dos inimigos com JumpMovement — não é uma investida, é um
/// pulo de verdade. Enquanto no ar, a invulnerabilidade concedida cobre tanto
/// projéteis quanto o toque de inimigos. Ao aterrissar, uma explosão empurra
/// tudo ao redor pra longe.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class JogadaDeCorpo extends Ability {
  final double distancia;
  final double duracao;
  final double altura;
  final double coef;
  final double empurrao;

  const JogadaDeCorpo({
    this.distancia = 40,
    this.duracao = 0.3,
    this.altura = 16,
    this.coef = 0.75,
    this.empurrao = 50,
  }) : super(
         nome: 'Jogada de Corpo',
         descricao:
             'Pulo invulnerável na direção do toque; a aterrissagem empurra tudo ao redor.',
         cooldown: 4.5,
         target: AbilityTarget.joyDir,
         tipo: AbilityTipo.esquiva,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.grantInvulnerability(duracao);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.startJump(
      direction: dir,
      distance: distancia,
      duration: duracao,
      height: altura,
      onLand: () {
        user.parent?.add(
          ExplosionHitbox(
            position: user.position.clone(),
            dmg: dano,
            knockback: empurrao,
            size: Vector2(40, 40),
            tipo: user.creatureData.tipo,
          ),
        );
      },
    );
  }
}
