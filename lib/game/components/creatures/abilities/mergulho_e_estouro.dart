import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Tubarão de Água — botão B. Mira no inimigo mais próximo (target padrão:
/// enemyDir) e mergulha em cima dele — invulnerável durante o pulo, explosão
/// ao emergir. Diferente de uma esquiva normal: não foge de nada, fecha
/// distância. Dano = ataque da criatura × [coef] — ver BaseStats.
class MergulhoEEstouro extends Ability {
  final double distancia;
  final double duracao;
  final double altura;
  final double coef;
  final double empurrao;

  const MergulhoEEstouro({
    this.distancia = 50,
    this.duracao = 0.6,
    this.altura = 20,
    this.coef = 1.0,
    this.empurrao = 70,
  }) : super(nome: 'Mergulho e Estouro', cooldown: 5.0, tipo: AbilityTipo.esquiva);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.grantInvulnerability(duracao);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.startJump(
      direction: dir,
      distance: distancia,
      duration: duracao-0.2,
      height: altura,
      onLand: () {
        user.parent?.add(ExplosionHitbox(
          position: user.position.clone(),
          dmg: dano,
          knockback: empurrao,
          size: Vector2(36, 36),
          tipo: user.creatureData.tipo,
        ));
      },
    );
  }
}
