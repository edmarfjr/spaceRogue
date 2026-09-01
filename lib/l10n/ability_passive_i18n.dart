import 'package:flutter/widgets.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/passive.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/bico_eletrico.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/baforada_de_cinzas.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/ericar.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/cuspe_venenoso.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/cuspe_de_semente.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/tiro_de_gelo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/choque_eletrico.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/soco_flamejante.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/deixar_bomba.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/rajada_de_brasa.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/folhas_navalha.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/mega_soco.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/mordida.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/estocada_relampago.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/bola_dagua.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/jato_aquatico.dart';
import 'package:creatures_rogue/game/components/creatures/passives/brado_reflexo.dart';
import 'package:creatures_rogue/game/components/creatures/passives/investida_predatoria.dart';
import 'package:creatures_rogue/game/components/creatures/passives/fumaca_ao_lacar.dart';
import 'package:creatures_rogue/game/components/creatures/passives/tornado_residual.dart';
import 'package:creatures_rogue/game/components/creatures/passives/golpe_de_lanca.dart';
import 'package:creatures_rogue/game/components/creatures/passives/bomba_na_esquiva.dart';
import 'package:creatures_rogue/game/components/creatures/passives/corrente_reflexa.dart';
import 'package:creatures_rogue/game/components/creatures/passives/salto_aquatico.dart';
import 'package:creatures_rogue/game/components/creatures/passives/rastro_congelante.dart';
import 'package:creatures_rogue/game/components/creatures/passives/bolha_autonoma.dart';
import 'package:creatures_rogue/game/components/creatures/passives/casco_reflexivo.dart';
import 'package:creatures_rogue/game/components/creatures/passives/raizes_do_laco.dart';
import 'package:creatures_rogue/game/components/creatures/passives/retaliacao_eletrica.dart';
import 'package:creatures_rogue/game/components/creatures/passives/pecoenha_reflexiva.dart';
import 'package:creatures_rogue/game/components/creatures/passives/rastro_flamejante.dart';
import 'package:creatures_rogue/game/components/creatures/passives/reflexo_eletrico.dart';
import 'l10n_extensions.dart';

/// Nome/descrição exibidos de uma `Ability`/`Passive`, pelo tipo concreto —
/// não muda `nome`/`descricao` nas ~50 classes de dado (são `const` montadas
/// antes de qualquer `BuildContext` existir). Só cobre as habilidades que
/// `ability1` de alguma criatura usa: as 16 `ability2` são dado morto (ver
/// `Ability.descricao`) e nunca aparecem em tela, então não precisam de
/// tradução.
String abilityName(BuildContext context, Ability a) {
  final l = context.l10n;
  return switch (a) {
    BicoEletrico() => l.abilityName_BicoEletrico,
    BaforadaDeCinzas() => l.abilityName_BaforadaDeCinzas,
    Ericar() => l.abilityName_Ericar,
    CuspeVenenoso() => l.abilityName_CuspeVenenoso,
    CuspeDeSemente() => l.abilityName_CuspeDeSemente,
    TiroDeGelo() => l.abilityName_TiroDeGelo,
    ChoqueEletrico() => l.abilityName_ChoqueEletrico,
    SocoFlamejante() => l.abilityName_SocoFlamejante,
    DeixarBomba() => l.abilityName_DeixarBomba,
    RajadaDeBrasa() => l.abilityName_RajadaDeBrasa,
    FolhasNavalha() => l.abilityName_FolhasNavalha,
    MegaSoco() => l.abilityName_MegaSoco,
    Mordida() => l.abilityName_Mordida,
    EstocadaRelampago() => l.abilityName_EstocadaRelampago,
    BolaDagua() => l.abilityName_BolaDagua,
    JatoAquatico() => l.abilityName_JatoAquatico,
    _ => a.nome,
  };
}

String abilityDescription(BuildContext context, Ability a) {
  final l = context.l10n;
  return switch (a) {
    BicoEletrico() => l.abilityDesc_BicoEletrico,
    BaforadaDeCinzas() => l.abilityDesc_BaforadaDeCinzas,
    Ericar() => l.abilityDesc_Ericar,
    CuspeVenenoso() => l.abilityDesc_CuspeVenenoso,
    CuspeDeSemente() => l.abilityDesc_CuspeDeSemente,
    TiroDeGelo() => l.abilityDesc_TiroDeGelo,
    ChoqueEletrico() => l.abilityDesc_ChoqueEletrico,
    SocoFlamejante() => l.abilityDesc_SocoFlamejante,
    DeixarBomba() => l.abilityDesc_DeixarBomba,
    RajadaDeBrasa() => l.abilityDesc_RajadaDeBrasa,
    FolhasNavalha() => l.abilityDesc_FolhasNavalha,
    MegaSoco() => l.abilityDesc_MegaSoco,
    Mordida() => l.abilityDesc_Mordida,
    EstocadaRelampago() => l.abilityDesc_EstocadaRelampago,
    BolaDagua() => l.abilityDesc_BolaDagua,
    JatoAquatico() => l.abilityDesc_JatoAquatico,
    _ => a.descricao,
  };
}

String passiveName(BuildContext context, Passive p) {
  final l = context.l10n;
  return switch (p) {
    BradoReflexo() => l.passiveName_BradoReflexo,
    InvestidaPredatoria() => l.passiveName_InvestidaPredatoria,
    FumacaAoLacar() => l.passiveName_FumacaAoLacar,
    TornadoResidual() => l.passiveName_TornadoResidual,
    GolpeDeLanca() => l.passiveName_GolpeDeLanca,
    BombaNaEsquiva() => l.passiveName_BombaNaEsquiva,
    CorrenteReflexa() => l.passiveName_CorrenteReflexa,
    SaltoAquatico() => l.passiveName_SaltoAquatico,
    RastroCongelante() => l.passiveName_RastroCongelante,
    BolhaAutonoma() => l.passiveName_BolhaAutonoma,
    CascoReflexivo() => l.passiveName_CascoReflexivo,
    RaizesDoLaco() => l.passiveName_RaizesDoLaco,
    RetaliacaoEletrica() => l.passiveName_RetaliacaoEletrica,
    PecoenhaReflexiva() => l.passiveName_PecoenhaReflexiva,
    RastroFlamejante() => l.passiveName_RastroFlamejante,
    ReflexoEletrico() => l.passiveName_ReflexoEletrico,
    _ => p.nome,
  };
}

String passiveDescription(BuildContext context, Passive p) {
  final l = context.l10n;
  return switch (p) {
    BradoReflexo() => l.passiveDesc_BradoReflexo,
    InvestidaPredatoria() => l.passiveDesc_InvestidaPredatoria,
    FumacaAoLacar() => l.passiveDesc_FumacaAoLacar,
    TornadoResidual() => l.passiveDesc_TornadoResidual,
    GolpeDeLanca() => l.passiveDesc_GolpeDeLanca,
    BombaNaEsquiva() => l.passiveDesc_BombaNaEsquiva,
    CorrenteReflexa() => l.passiveDesc_CorrenteReflexa,
    SaltoAquatico() => l.passiveDesc_SaltoAquatico,
    RastroCongelante() => l.passiveDesc_RastroCongelante,
    BolhaAutonoma() => l.passiveDesc_BolhaAutonoma,
    CascoReflexivo() => l.passiveDesc_CascoReflexivo,
    RaizesDoLaco() => l.passiveDesc_RaizesDoLaco,
    RetaliacaoEletrica() => l.passiveDesc_RetaliacaoEletrica,
    PecoenhaReflexiva() => l.passiveDesc_PecoenhaReflexiva,
    RastroFlamejante() => l.passiveDesc_RastroFlamejante,
    ReflexoEletrico() => l.passiveDesc_ReflexoEletrico,
    _ => p.descricao,
  };
}
