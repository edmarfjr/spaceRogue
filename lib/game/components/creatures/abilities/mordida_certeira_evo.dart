import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Evolução de [MordidaCerteira]: mesma investida teleguiada, mais longa e
/// mais forte.
///
/// O roubo de vida do Doguin evoluído NÃO mora aqui — mora na passiva
/// `FaroDoPredador` (ver `CreatureData.passive`), que cura no CRÍTICO.
///
/// A distinção importa: curar a cada acerto daria ~1,1 de vida por segundo
/// numa barra de 6, ou seja a barra inteira a cada 5 segundos, o que apagaria
/// o dano como recurso. Preso ao crítico, o mesmo efeito sai a ~0,19 por
/// segundo e ainda transforma `critChanceUp`, Sangue Frio e Gatilho Frio em
/// itens de build pra esta criatura.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class MordidaCerteiraEvo extends Ability {
  final double distancia;
  final double duracao;
  final double coef;

  const MordidaCerteiraEvo({
    this.distancia = 36,
    this.duracao = 0.2,
    this.coef = 1.5,
  }) : super(
         nome: 'Mordida Faminta',
         descricao:
             'Investida que mira sozinha; o crítico arranca um naco de vida.',
         // Regra do elenco: cadência sai do `custoEnergia`, não do cooldown.
         cooldown: 0.4,
         custoEnergia: 2.5,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.grantInvulnerability(duracao + 0.3);
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
