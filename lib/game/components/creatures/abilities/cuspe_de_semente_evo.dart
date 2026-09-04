import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [CuspeDeSemente] (ver `PIVOT_EVOLUCAO`): a semente agora
/// perfura (`atravessa: 2`) — atinge um segundo inimigo na mesma linha em vez
/// de se desfazer no primeiro.
class CuspeDeSementeEvo extends Ability {
  final double coef;
  final double velocidade;
  final double kbForce;

  const CuspeDeSementeEvo({
    this.coef = 1.4,
    this.velocidade = 90,
    this.kbForce = 30,
  }) : super(nome: 'Cuspe de Semente+', cooldown: 1.4);

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
        kbForce: kbForce,
        atravessa: 2,
        sprPath: 'projeteis/proj1.png',
        cor1: Palette.verde,
        cor2: Palette.verdeEsc,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
