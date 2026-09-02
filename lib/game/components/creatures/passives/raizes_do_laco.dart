import '../passive.dart';

/// Toco de Madeira — antes reduzia o dano recebido enquanto o laço de captura
/// estava ativo (PIVOT_TREINADOR.md §4.1). O laço saiu do jogo
/// (PIVOT_CONTROLE_DIRETO.md §2.4) e essa passiva ficou sem gancho —
/// placeholder neutro até a criatura ganhar uma passiva nova.
class RaizesDoLaco extends Passive {
  const RaizesDoLaco()
      : super(nome: 'Raízes do Laço', descricao: 'Sem efeito no momento.');
}
