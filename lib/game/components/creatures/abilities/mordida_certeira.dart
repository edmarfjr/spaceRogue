import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Cão Neutro — botão A. Investida curta que MIRA sozinha no inimigo mais
/// próximo (`target` padrão: `enemyDir`) — o jogador não precisa apontar, o
/// cão fareja. Termina em mordida no ponto de chegada.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class MordidaCerteira extends Ability {
  final double distancia;
  final double duracao;
  final double coef;

  const MordidaCerteira({
    this.distancia = 28,
    this.duracao = 0.2,
    this.coef = 1.2,
  }) : super(
         nome: 'Mordida Certeira',
         descricao: 'Investida que mira sozinha no inimigo mais próximo.',
         cooldown: 0.9,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.grantInvulnerability(duracao+0.3);
    user.add(
      MoveByEffect(
        dir.normalized() * distancia,
        EffectController(duration: duracao),
        onComplete: () {
          user.parent?.add(
            ExplosionHitbox(
              position: user.position.clone(),
              dmg: dano,
              tipo: user.creatureData.tipo,
              size: Vector2(20, 20),
            ),
          );
        },
      ),
    );
  }
}
