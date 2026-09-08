import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Peixe Neutro — botão B. Janela de imunidade a lentidão, cegueira e
/// empurrão (`grantStatusImmunity`) — NÃO bloqueia dano, só status. Nicho
/// que nenhuma outra habilidade cobre: toda "defesa" do elenco bloqueia
/// dano, não status.
class EscamasEscorregadias extends Ability {
  final double duracao;

  const EscamasEscorregadias({this.duracao = 3.0})
    : super(
        nome: 'Escamas Escorregadias',
        descricao: 'Imune a lentidão, cegueira e empurrão por um tempo.',
        cooldown: 6.0,
        tipo: AbilityTipo.defesa,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantStatusImmunity(duracao);
  }
}
