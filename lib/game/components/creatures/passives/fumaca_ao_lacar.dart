import '../passive.dart';

/// Caranguejo Ermitão de Fogo — antes disparava fumaça ao travar o laço de
/// captura (PIVOT_TREINADOR.md §4.1). O laço saiu do jogo
/// (PIVOT_CONTROLE_DIRETO.md §2.4) e essa passiva ficou sem gancho — placeholder
/// neutro até a criatura ganhar uma passiva nova.
class FumacaAoLacar extends Passive {
  const FumacaAoLacar()
      : super(nome: 'Fumaça ao Laçar', descricao: 'Sem efeito no momento.');
}
