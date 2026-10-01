import 'package:flutter/widgets.dart';
import 'l10n_extensions.dart';

/// Nome exibido de uma criatura, pelo `id` de `CreatureData` — não muda
/// `nome` em `CreatureRegistry` (fica como fallback/identificador interno em
/// pt, sem `BuildContext` no momento em que o registry é montado).
String creatureName(BuildContext context, String creatureId) {
  final l = context.l10n;
  return switch (creatureId) {
    'roedor_fogo' => l.creatureName_roedor_fogo,
    'tartaruga_planta' => l.creatureName_tartaruga_planta,
    'sapo_agua' => l.creatureName_sapo_agua,
    'ave_eletrica' => l.creatureName_ave_eletrica,
    'cobra_agua' => l.creatureName_cobra_agua,
    'urso_planta' => l.creatureName_urso_planta,
    'grilo_eletrico' => l.creatureName_grilo_eletrico,
    'tornado_fogo' => l.creatureName_tornado_fogo,
    'bomba_fogo' => l.creatureName_bomba_fogo,
    'slime_planta' => l.creatureName_slime_planta,
    'ourico_eletrico' => l.creatureName_ourico_eletrico,
    'caranguejo_fogo' => l.creatureName_caranguejo_fogo,
    'pinguim_agua' => l.creatureName_pinguim_agua,
    'toco_planta' => l.creatureName_toco_planta,
    'tubarao_agua' => l.creatureName_tubarao_agua,
    'leao_eletrico' => l.creatureName_leao_eletrico,
    'cao_neutro' => l.creatureName_cao_neutro,
    'gato_neutro' => l.creatureName_gato_neutro,
    'ave_neutro' => l.creatureName_ave_neutro,
    'peixe_neutro' => l.creatureName_peixe_neutro,
    'roda_fogo' => l.creatureName_roda_fogo,
    'cogumelo_planta' => l.creatureName_cogumelo_planta,
    _ => creatureId,
  };
}

/// Uma frase sobre o JEITO DE JOGAR da criatura, mostrada na tela de escolha.
///
/// Fala de postura (rápida, teimosa, de longe, de perto), e não das
/// habilidades: os nomes delas aparecem logo abaixo no mesmo painel, e
/// repetir ali seria gastar duas linhas pra dizer a mesma coisa.
///
/// Mesma via do [creatureName] — indexado por `id`, sem campo novo no
/// `CreatureData`. Forma evoluída compartilha o `id`, então herda a frase.
String creatureDescription(BuildContext context, String creatureId) {
  final l = context.l10n;
  return switch (creatureId) {
    'ave_eletrica' => l.creatureDesc_ave_eletrica,
    'ave_neutro' => l.creatureDesc_ave_neutro,
    'bomba_fogo' => l.creatureDesc_bomba_fogo,
    'cao_neutro' => l.creatureDesc_cao_neutro,
    'caranguejo_fogo' => l.creatureDesc_caranguejo_fogo,
    'cobra_agua' => l.creatureDesc_cobra_agua,
    'cogumelo_planta' => l.creatureDesc_cogumelo_planta,
    'gato_neutro' => l.creatureDesc_gato_neutro,
    'grilo_eletrico' => l.creatureDesc_grilo_eletrico,
    'leao_eletrico' => l.creatureDesc_leao_eletrico,
    'ourico_eletrico' => l.creatureDesc_ourico_eletrico,
    'peixe_neutro' => l.creatureDesc_peixe_neutro,
    'pinguim_agua' => l.creatureDesc_pinguim_agua,
    'roda_fogo' => l.creatureDesc_roda_fogo,
    'roedor_fogo' => l.creatureDesc_roedor_fogo,
    'sapo_agua' => l.creatureDesc_sapo_agua,
    'slime_planta' => l.creatureDesc_slime_planta,
    'tartaruga_planta' => l.creatureDesc_tartaruga_planta,
    'toco_planta' => l.creatureDesc_toco_planta,
    'tornado_fogo' => l.creatureDesc_tornado_fogo,
    'tubarao_agua' => l.creatureDesc_tubarao_agua,
    'urso_planta' => l.creatureDesc_urso_planta,
    _ => '',
  };
}
