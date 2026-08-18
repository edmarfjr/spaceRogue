import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:spacerogue/game/components/creatures/ability.dart';
import 'package:spacerogue/game/components/player/player.dart';
import 'package:spacerogue/game/components/projeteis/explosion_hitbox.dart';

/// Cobra de Água — botão B. Salta na direção apontada; enquanto no ar, a
/// invulnerabilidade concedida cobre tanto projéteis quanto o toque de
/// inimigos. Ao aterrissar, uma explosão empurra tudo ao redor pra longe.
class JogadaDeCorpo extends Ability {
  final double distancia;
  final double duracao;
  final int dano;
  final double empurrao;

  const JogadaDeCorpo({
    this.distancia = 40,
    this.duracao = 0.3,
    this.dano = 3,
    this.empurrao = 50,
  }) : super(nome: 'Jogada de Corpo', cooldown: 4.5, target: AbilityTarget.joyDir);

  @override
  void execute(Player user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    user.add(MoveByEffect(
      dir.normalized() * distancia,
      EffectController(duration: duracao),
      onComplete: () {
        user.parent?.add(ExplosionHitbox(
          position: user.position.clone(),
          dmgPlr: 0,
          dmgEnemy: dano,
          knockback: empurrao,
          size: Vector2(40, 40),
        ));
      },
    ));
  }
}
