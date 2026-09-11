import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Ave Neutro — botão B. Voo curto e invulnerável — mobilidade PURA, sem
/// dano no fim (diferente de todo outro dash do elenco, que sempre bate ou
/// planta algo ao terminar). Alcance maior que os outros dashes porque não
/// precisa compensar dano nenhum.
class VooAlto extends Ability {
  final double distancia;
  final double duracao;

  const VooAlto({this.distancia = 56, this.duracao = 0.3})
    : super(
        nome: 'Vôo Alto',
        descricao: 'Voo curto e invulnerável — mobilidade pura, sem dano.',
        cooldown: 3.5,
        target: AbilityTarget.plrDir,
        tipo: AbilityTipo.esquiva,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(
      MoveByEffect(
        user.dashOffsetLivre(dir, distancia),
        EffectController(duration: duracao),
      ),
    );
  }
}
