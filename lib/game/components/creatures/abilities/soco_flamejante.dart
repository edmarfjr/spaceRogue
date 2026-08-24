import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tornado de Fogo — botão A. Cooldown baixo, dano alto, alcance
/// curto.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class SocoFlamejante extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  const SocoFlamejante({this.coef = 1.0, this.velocidade = 260, this.alcanceSegundos = 0.15})
      : super(nome: 'Soco Flamejante', cooldown: 0.4);

  @override
  void execute(Player user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/soco.png',
      lifeTime: alcanceSegundos,
      cor1: Palette.vermelho,
      cor2: Palette.roxoEsc,
      tipo: user.creatureData.tipo,
    ));
  }
}
