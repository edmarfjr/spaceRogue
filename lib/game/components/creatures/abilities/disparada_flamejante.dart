import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/creatures/ability.dart';
import 'package:spacerogue/game/components/player/player.dart';
import 'package:spacerogue/game/components/projeteis/explosion_hitbox.dart';

/// Roedor de Fogo — botão B. Dash com i-frames, deixa rastro de dano.
/// Mobilidade é a defesa de uma criatura frágil.
class DisparadaFlamejante extends Ability {
  final double distancia;
  final double duracao;
  final int danoRastro;

  const DisparadaFlamejante({
    this.distancia = 24,
    this.duracao = 0.15,
    this.danoRastro = 2,
  }) : super(nome: 'Disparada Flamejante', cooldown: 4.0, target: AbilityTarget.plrDir);

  @override
  void execute(Player user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    final origem = user.position.clone();
    user.parent?.add(ExplosionHitbox(position: origem, dmgPlr: 0, dmgEnemy: danoRastro));

    user.add(MoveByEffect(
      dir.normalized() * distancia,
      EffectController(duration: duracao),
      onComplete: () {
        user.parent?.add(ExplosionHitbox(
          position: user.position.clone(),
          dmgPlr: 0,
          dmgEnemy: danoRastro,
          cor2: Palette.laranja
        ));
      },
    ));
  }
}
