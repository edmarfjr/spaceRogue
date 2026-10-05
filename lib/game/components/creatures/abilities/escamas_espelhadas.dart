import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

/// Evolução de [EscamasEscorregadias]: a mesma janela de imunidade a status,
/// mas cada status bloqueado RICOCHETEIA nos inimigos em volta.
///
/// O verbo muda de ignorar pra devolver: a forma base só deixa o status
/// escorregar, esta transforma o campo de lentidão do Pinguim ou a nuvem que
/// cega numa arma contra quem estiver perto. Continua sem bloquear dano —
/// ver `Player._refletirStatus`.
class EscamasEspelhadas extends Ability {
  final double duracao;

  const EscamasEspelhadas({this.duracao = 3.0})
    : super(
        nome: 'Escamas Espelhadas',
        descricao:
            'Imune a lentidão, cegueira e empurrão, e devolve esses efeitos a quem estiver perto.',
        cooldown: 6.0,
        tipo: AbilityTipo.defesa,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantStatusImmunity(duracao);
    if (user is Player) user.ativarEspelhoDeStatus(duracao);
  }
}
