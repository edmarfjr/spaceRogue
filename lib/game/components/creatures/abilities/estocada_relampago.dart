import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Leão Elétrico — botão A. Lança fina e rápida, atravessa até 3 alvos numa
/// linha só — o alcance dele, contra as investidas de corpo do resto do
/// elenco elétrico. Dano = ataque da criatura × [coef] — ver BaseStats.
class EstocadaRelampago extends Ability {
  final double coef;
  final double velocidade;
  final int atravessa;

  const EstocadaRelampago({this.coef = 0.9, this.velocidade = 160, this.atravessa = 3})
      : super(nome: 'Estocada Relâmpago', cooldown: 1.4);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone() + dir.normalized() * user.size.x / 2,
      direction: dir,
      speed: velocidade,
      dmg: dano,
      atravessa: atravessa,
      sprPath: 'projeteis/proj2.png',
      cor1: user.creatureData.corClara,
      cor2: user.creatureData.corEscura,
      tipo: user.creatureData.tipo,
    ));
  }
}
