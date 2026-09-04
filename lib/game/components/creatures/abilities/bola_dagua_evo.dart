import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [BolaDagua] (ver `PIVOT_EVOLUCAO`): ao acabar (acertar algo ou
/// alcance máximo), respinga em três fragmentos menores (`fragmentos: 3`) —
/// o Sapo evoluído troca "sem truque" por um splash de área na chegada.
class BolaDaguaEvo extends Ability {
  final double coef;
  final double velocidade;

  const BolaDaguaEvo({this.coef = 1.5, this.velocidade = 220})
    : super(nome: "Bola d'Água+", cooldown: 0.6);

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
        fragmentos: 3,
        sprPath: 'projeteis/proj1.png',
        cor1: Palette.azul,
        cor2: Palette.azulEsc,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
