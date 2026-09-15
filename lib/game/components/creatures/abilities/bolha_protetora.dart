import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Sapo de Água — botão B. Escudo que absorve um golpe, com duração limitada.
class BolhaProtetora extends Ability {
  final double duracao;

  const BolhaProtetora({this.duracao = 5.0})
    : super(
        nome: 'Bolha Protetora',
        descricao: 'Escudo que absorve um golpe por um tempo.',
        cooldown: 7.0,
        tipo: AbilityTipo.defesa,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.adicionarEscudoTemporario(#bolhaProtetora, 1, duracao);
  }
}
