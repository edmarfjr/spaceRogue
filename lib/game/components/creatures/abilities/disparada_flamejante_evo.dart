import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Evolução de [DisparadaFlamejante] (ver `PIVOT_EVOLUCAO`): mesmo dash com
/// i-frames e rastro, mas mais longo e com uma explosão de chegada maior em
/// vez do dano igual ao do rastro — o Roedor evoluído fecha a investida com
/// um estouro, não só mais um tapa de fogo.
class DisparadaFlamejanteEvo extends Ability {
  final double distancia;
  final double duracao;
  final double coefRastro;
  final double coefExplosaoFinal;

  const DisparadaFlamejanteEvo({
    this.distancia = 48,
    this.duracao = 0.2,
    this.coefRastro = 0.8,
    this.coefExplosaoFinal = 1.4,
  }) : super(
         nome: 'Disparada Flamejante+',
         descricao:
             'Dash maior com i-frames; o rastro queima mais e termina num estouro.',
         cooldown: 1.3,
         target: AbilityTarget.plrDir,
         tipo: AbilityTipo.esquiva,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final ataque = user.creatureData.stats.ataque;
    user.grantInvulnerability(duracao);

    final origem = user.position.clone();
    user.parent?.add(
      ExplosionHitbox(
        position: origem,
        dmg: ataque * coefRastro,
        cor2: Palette.laranja,
        tipo: user.creatureData.tipo,
        dotKind: DotKind.queimadura,
        dotTicks: 5,
      ),
    );

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(
      MoveByEffect(
        dir.normalized() * distancia,
        EffectController(duration: duracao),
        onComplete: () {
          user.parent?.add(
            ExplosionHitbox(
              position: user.position.clone(),
              dmg: ataque * coefExplosaoFinal,
              cor2: Palette.laranja,
              tipo: user.creatureData.tipo,
              dotKind: DotKind.queimadura,
              dotTicks: 5,
              size: Vector2(40, 40),
            ),
          );
        },
      ),
    );
  }
}
