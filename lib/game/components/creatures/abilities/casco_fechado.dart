import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Tartaruga de Planta — botão B. Reduz dano recebido em troca de ficar parada.
/// Trocar mobilidade por sobrevivência é a decisão que define a criatura.
class CascoFechado extends Ability {
  final double reducaoDano;
  final double duracao;

  const CascoFechado({this.reducaoDano = 1, this.duracao = 2.5})
      : super(nome: 'Casco Fechado', cooldown: 6.0,tipo: AbilityTipo.defesa);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.damageReduction = reducaoDano;
    user.speedLocked = true;
    user.shieldVisualActive = true;
    user.refleteProjetil = true;

    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted) {
        user.damageReduction = 0.0;
        user.speedLocked = false;
        user.shieldVisualActive = false;
        user.refleteProjetil = false;
      }
    });
  }
}
