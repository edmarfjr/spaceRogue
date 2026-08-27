import '../../player/player.dart';
import '../passive.dart';

/// Sapo de Água — antes era `BolhaProtetora` (botão B). Sem botão pra
/// recarregar sozinha, a bolha original vira um escudo de 1 golpe que se
/// forma automaticamente depois de um tempo sem o treinador apanhar
/// (`Player.tempoSemApanhar`, resetado em `Player.takeDamage`) — mesma ideia
/// (escudo temporário), mecanismo de recarga diferente porque não há botão
/// nenhum pra segurar.
class BolhaAutonoma extends Passive {
  final double tempoParaFormar;
  const BolhaAutonoma({this.tempoParaFormar = 5.0}) : super(nome: 'Bolha Autônoma', descricao: 'Depois de um tempo sem apanhar, o treinador forma sozinho um escudo que absorve um golpe.');

  @override
  void aoAtualizar(Player player, double dt) {
    if (player.shieldHits > 0) return;
    if (player.tempoSemApanhar < tempoParaFormar) return;
    player.shieldHits = 1;
    player.shieldVisualActive = true;
  }
}
