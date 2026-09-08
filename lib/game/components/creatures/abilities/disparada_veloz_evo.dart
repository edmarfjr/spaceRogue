import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Grilo Eletrico — botão B. Dash com i-frames.
/// Mobilidade é a defesa de uma criatura frágil.
class DisparadaVelozEvo extends Ability {
  final double distancia;
  final double duracao;

  const DisparadaVelozEvo({this.distancia = 32, this.duracao = 0.15})
    : super(
        nome: 'Disparada Veloz',
        descricao: 'Dash rápido com i-frames.',
        cooldown: 0.75,
        target: AbilityTarget.plrDir,
        tipo: AbilityTipo.esquiva,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantInvulnerability(duracao+0.2);
  
    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(
      MoveByEffect(
        dir.normalized() * distancia,
        EffectController(duration: duracao),
        onComplete: () {},
      ),
    );
  }
}
