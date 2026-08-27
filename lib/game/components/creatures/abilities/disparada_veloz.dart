import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Grilo Eletrico — botão B. Dash com i-frames.
/// Mobilidade é a defesa de uma criatura frágil.
class DisparadaVeloz extends Ability {
  final double distancia;
  final double duracao;

  const DisparadaVeloz({
    this.distancia = 24,
    this.duracao = 0.15,
  }) : super(nome: 'Disparada Veloz', cooldown: 1.0, target: AbilityTarget.plrDir,tipo: AbilityTipo.esquiva);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(MoveByEffect(
      dir.normalized() * distancia,
      EffectController(duration: duracao),
      onComplete: () {
      },
    ));
  }
}
