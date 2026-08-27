import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Toco de Madeira — botão B. Crava raízes: reduz o dano recebido em troca de
/// ficar parado, igual Casco Fechado, mas parcial — o toco não fecha de vez,
/// só endurece a casca.
class Enraizar extends Ability {
  final double reducaoDano;
  final double duracao;

  const Enraizar({this.reducaoDano = 1.0, this.duracao = 3.5})
      : super(nome: 'Enraizar', cooldown: 7.0, tipo: AbilityTipo.defesa);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.damageReduction = reducaoDano;
    user.speedLocked = true;
    user.shieldVisualActive = true;

    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted) {
        user.damageReduction = 0.0;
        user.speedLocked = false;
        user.shieldVisualActive = true;
      }
    });
  }
}
