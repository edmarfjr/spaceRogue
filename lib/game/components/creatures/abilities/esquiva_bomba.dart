import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

/// Tornado de Fogo — botão B. Evasiva com i-frames, deixa rastro de dano.
class EsquivaBomba extends Ability {
  final double distancia;
  final double duracao;

  const EsquivaBomba({
    this.distancia = 32,
    this.duracao = 0.15,
  }) : super(nome: 'Esquiva Bomba', cooldown: 4.0, target: AbilityTarget.plrDir);

  @override
  void execute(Player user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    user.placeBomb(user.lockedAb2Direction);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(MoveByEffect(
      -dir.normalized() * distancia,
      EffectController(duration: duracao),
      onComplete: () {
        
      },
    ));
  }
}
