import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Ave de Eletricidade — botão A. Cooldown baixíssimo, dano baixo, alcance
/// curto. O DPS vem do volume de disparos, não do golpe individual.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class BicoEletrico extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  const BicoEletrico({this.coef = 1.0, this.velocidade = 260, this.alcanceSegundos = 0.25})
      : super(nome: 'Bico Elétrico', cooldown: 0.25);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/proj2.png',
      lifeTime: alcanceSegundos,
      cor1: Palette.amarelo,
      cor2: Palette.laranja,
      tipo: user.creatureData.tipo,
    ));
  }
}
