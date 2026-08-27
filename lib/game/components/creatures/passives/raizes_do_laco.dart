import '../passive.dart';

/// Toco de Madeira — antes era `Enraizar` (botão B). Puramente numérico: o
/// treinador recebe metade do dano enquanto o laço de captura está ativo —
/// lido direto em `Player.takeDamage` a partir de `Player.capturando`, sem
/// hook de início/fim de laço nenhum.
class RaizesDoLaco extends Passive {
  const RaizesDoLaco() : super(nome: 'Raízes do Laço', descricao: 'O treinador recebe metade do dano enquanto o laço de captura está ativo.', reducaoDuranteLaco: 0.5);
}
