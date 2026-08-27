import '../../core/palette.dart';
import '../../player/player.dart';
import '../../projeteis/explosion_hitbox.dart';
import '../passive.dart';

/// Ave Elétrica — antes era `CorrenteEstática` (botão B). Todo golpe que o
/// treinador tenta tomar solta uma descarga ao redor dele, atordoando quem
/// estiver perto — mesmos números da habilidade original.
///
/// Nota de playtest: junto com `RetaliacaoEletrica` (Ouriço), duas fontes de
/// atordoamento simultâneas somam ~1.5s de sala travada por golpe recebido —
/// não ajustado aqui de propósito (o usuário travou "as três executam", não
/// pediu limite); vale conferir em jogo se isso lê como forte demais.
class CorrenteReflexa extends Passive {
  final double coef;
  final double stunDuration;
  const CorrenteReflexa({this.coef = 1.0, this.stunDuration = 1.5})
      : super(nome: 'Corrente Reflexa', descricao: 'Todo golpe que o treinador tenta tomar solta uma descarga ao redor dele, que atordoa.');

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(ExplosionHitbox(
      position: player.position.clone(),
      dmg: player.creatureData.stats.ataque * coef,
      isStun: true,
      stunDuration: stunDuration,
      cor1: Palette.amarelo,
      cor2: Palette.laranja,
    ));
  }
}
