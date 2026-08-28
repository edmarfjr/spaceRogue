import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Leão Elétrico — botão B. Dash com i-frames na direção do movimento,
/// golpe de lança só no FINAL do trajeto — diferente das disparadas que
/// atropelam no caminho inteiro, aqui é o pouso que machuca.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class InvestidaDaLanca extends Ability {
  final double distancia;
  final double duracao;
  final double coef;
  final double empurrao;

  const InvestidaDaLanca({
    this.distancia = 36,
    this.duracao = 0.2,
    this.coef = 2.5,
    this.empurrao = 80,
  }) : super(nome: 'Investida da Lança', cooldown: 4.0, target: AbilityTarget.plrDir, tipo: AbilityTipo.esquiva);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
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
        user.parent?.add(ExplosionHitbox(
          position: user.position.clone(),
          dmg: dano,
          knockback: empurrao,
          size: Vector2(24, 24),
          tipo: user.creatureData.tipo,
        ));
      },
    ));
  }
}
