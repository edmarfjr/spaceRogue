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
    _ => creatureId,
  };
}
