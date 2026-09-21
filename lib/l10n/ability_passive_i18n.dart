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
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/passives/roda_de_fogo.dart';
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
    // `RodaDeFogoEvo` ANTES da base: ela E uma `RodaDeFogo`, e o switch casa
    // no primeiro padrao — invertido, a evoluida mostraria o texto da base.
    RodaDeFogoEvo() => l.passiveName_RodaDeFogoEvo,
    RodaDeFogo() => l.passiveName_RodaDeFogo,
    _ => p.nome,
  };
}

String passiveDescription(BuildContext context, Passive p) {
  final l = context.l10n;
  return switch (p) {
    RodaDeFogoEvo() => l.passiveDesc_RodaDeFogoEvo,
    RodaDeFogo() => l.passiveDesc_RodaDeFogo,
    _ => p.nome,
  };
}

/// Nome e descrição do que ocupa o lugar da habilidade 1 de [criatura]: a
/// própria habilidade, ou a PASSIVA quando ela não tem habilidade 1 (ver
/// `CreatureData.ability1`). Existe pra que as três telas de criatura
/// (seleção, intro e pausa) não repitam esse `if` cada uma à sua moda.
({String nome, String descricao}) slotUmDaCriatura(
  BuildContext context,
  CreatureData criatura,
) {
  final ability = criatura.ability1;
  if (ability != null) {
    return (
      nome: abilityName(context, ability),
      descricao: abilityDescription(context, ability),
    );
  }

  final passive = criatura.passive;
  if (passive != null) {
    return (
      nome: passiveName(context, passive),
      descricao: passiveDescription(context, passive),
    );
  }

  return (nome: '-', descricao: '-');
}
