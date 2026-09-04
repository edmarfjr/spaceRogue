import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

class DisparadaCongelante extends Ability {
  final double distancia;
  final double duracao;
  final double coefRastro;

  const DisparadaCongelante({
    this.distancia = 32,
    this.duracao = 0.15,
    this.coefRastro = 0.5,
  }) : super(nome: 'Disparada Congelante', cooldown: 3.0, target: AbilityTarget.plrDir,tipo: AbilityTipo.esquiva);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final danoRastro = user.creatureData.stats.ataque * coefRastro;
    user.grantInvulnerability(duracao);

    final origem = user.position.clone();
    user.parent?.add(ExplosionHitbox(
      position: origem, 
      dmg: danoRastro, 
      cor1: Palette.royal,
      cor2: Palette.azul,
      tipo: user.creatureData.tipo,
      lentidaoDuracao: 3.0,
    ));

    user.parent?.add(Projectile(
      owner: user,
      position: origem,
      direction: Vector2.zero(),
      speed: 0,
      dmg: 0,
      kbForce: 0,
      sprPath: 'projeteis/bolaGrande.png',
      cor1: Palette.royal,
      cor2: Palette.azul,
      lentidaoDuracao: 3.0,
      atravessa: 10,
      size: Vector2(24, 24),
      lifeTime: 1.5,
      radius: 12,
    ));

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
          cor1: Palette.royal,
          cor2: Palette.azul,
          tipo: user.creatureData.tipo,
          lentidaoDuracao: 3.0,
        ));
      },
    ));
  }
}
