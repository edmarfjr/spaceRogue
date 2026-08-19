import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Roedor de Fogo — botão B. Dash com i-frames, deixa rastro de dano.
/// Mobilidade é a defesa de uma criatura frágil.
class DisparadaFlamejante extends Ability {
  final double distancia;
  final double duracao;
  final double danoRastro;

  const DisparadaFlamejante({
    this.distancia = 32,
    this.duracao = 0.15,
    this.danoRastro = 2,
  }) : super(nome: 'Disparada Flamejante', cooldown: 4.0, target: AbilityTarget.plrDir);

  @override
  void execute(Player user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    final origem = user.position.clone();
    user.parent?.add(ExplosionHitbox(position: origem,dmg: danoRastro));

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
          dmg: danoRastro,
          cor2: Palette.laranja
        ));
      },
    ));
  }
}
