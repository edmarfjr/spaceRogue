import 'package:flame/components.dart';
import '../../player/player.dart';
import '../passive.dart';

/// Bomba de Fogo — antes era `DeixarBomba`/`EsquivaBomba` (botões A/B). Toda
/// esquiva do treinador larga uma bomba pra trás, se ele tiver estoque
/// (`Player.bombsAmount`, recurso do treinador — ver PIVOT_TREINADOR.md
/// §3.2). Sem bomba, a esquiva acontece igual, só sem largar nada — a
/// mobilidade nunca depende do recurso, só a bomba em si.
class BombaNaEsquiva extends Passive {
  const BombaNaEsquiva() : super(nome: 'Bomba na Esquiva', descricao: 'Toda esquiva do treinador larga uma bomba pra trás, se houver estoque.');

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    if (player.bombsAmount > 0) player.placeBomb(-direcao);
  }
}
