import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Ave Neutro — botão A. Cadência altíssima, dano baixo, alcance curto — o
/// DPS vem do volume de disparos, não do golpe individual.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class BicadaRapida extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  const BicadaRapida({
    this.coef = 1.0,
    this.velocidade = 260,
    this.alcanceSegundos = 0.25,
  }) : super(
         nome: 'Bicada Rápida',
         descricao: 'Cadência altíssima, dano baixo por tiro.',
         cooldown: 0.25,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(
      Projectile(
        owner: user,
        position: user.position.clone(),
        direction: dir,
        speed: velocidade,
        dmg: dano,
        sprPath: 'projeteis/proj2.png',
        lifeTime: alcanceSegundos,
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
