import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

/// Sapo de Água — botão B. Escudo que absorve um golpe, com duração limitada.
class BolhaProtetora extends Ability {
  final double duracao;

  const BolhaProtetora({this.duracao = 5.0})
      : super(nome: 'Bolha Protetora', cooldown: 7.0,tipo: AbilityTipo.defesa);

  @override
  void execute(Player user, Vector2 dir) {
    user.shieldHits = 1;
    user.shieldVisualActive = true;

    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted && user.shieldHits > 0) {
        user.shieldHits = 0;
        user.shieldVisualActive = false;
      }
    });
  }
}
