import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Tornado de Fogo — botão B. Evasiva com i-frames, deixa rastro de dano.
class EsquivaBomba extends Ability {
  final double distancia;
  final double duracao;

  const EsquivaBomba({this.distancia = 32, this.duracao = 0.15})
    : super(
        nome: 'Esquiva Bomba',
        descricao: 'Evasiva com i-frames que também planta uma bomba.',
        cooldown: 4.0,
        target: AbilityTarget.plrDir,
        tipo: AbilityTipo.esquiva,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    // A mobilidade (dash + i-frames) é a metade defensiva desta habilidade e
    // não depende do recurso — só a bomba em si é suprimida sem estoque (ver
    // PIVOT_TREINADOR.md §3.2).
    if (user.bombsAmount > 0) user.placeBomb(user.lockedAb2Direction);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(
      MoveByEffect(
        -dir.normalized() * distancia,
        EffectController(duration: duracao),
        onComplete: () {},
      ),
    );
  }
}
