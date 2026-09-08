import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tornado de Fogo — botão A. Cooldown baixo, dano alto, alcance
/// curto.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class SocoFlamejanteEvo extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  const SocoFlamejanteEvo({this.coef = 1.0, this.velocidade = 260, this.alcanceSegundos = 0.15})
      : super(nome: 'Soco Flamejante', descricao: 'Cooldown baixo, dano alto, alcance curto.', cooldown: 0.4);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final direction = dir.clone();

    for (int i = 0; i < 2; i++) {
      Future.delayed(Duration(milliseconds: (i * 0.16 * 1000).round()), () {
        if (!user.isMounted) return;
        user.parent?.add(Projectile(
          owner: user,
          position: user.position.clone(),
          direction: direction,
          speed: velocidade,
          dmg: dano,
          sprPath: 'projeteis/soco.png',
          lifeTime: alcanceSegundos,
          cor1: Palette.vermelho,
          cor2: Palette.roxoEsc,
          tipo: user.creatureData.tipo,
        ));
      });
    }
  }
}
