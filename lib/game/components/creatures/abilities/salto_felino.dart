import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Gato Neutro — botão B. Salto invulnerável na direção do movimento,
/// arranhando ao pousar — mobilidade OFENSIVA, diferente de todo dash
/// evasivo do resto do elenco (que não causa dano).
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class SaltoFelino extends Ability {
  final double distancia;
  final double duracao;
  final double coef;

  const SaltoFelino({this.distancia = 40, this.duracao = 0.2, this.coef = 1.0})
    : super(
        nome: 'Salto Felino',
        descricao: 'Salto invulnerável que termina em arranhão.',
        cooldown: 3.0,
        target: AbilityTarget.plrDir,
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

    user.add(
      MoveByEffect(
        user.dashOffsetLivre(dir, distancia),
        EffectController(duration: duracao),
        onComplete: () {
          user.parent?.add(
            ExplosionHitbox(
              position: user.position.clone(),
              dmg: dano,
              tipo: user.creatureData.tipo,
              size: Vector2(24, 24),
            ),
          );
        },
      ),
    );
  }
}
