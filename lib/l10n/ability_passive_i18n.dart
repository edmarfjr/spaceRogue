import 'package:flutter/widgets.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/passive.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esporo_errante.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/casulo_de_esporos.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/casulo_de_esporos_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/bico_eletrico.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/bolha_protetora.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/bolha_protetora_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/brado.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/brado_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/casco_fechado.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/casco_fechado_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/corrente_estatica.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/corrente_estatica_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/disparada_congelante.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/disparada_congelante_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/disparada_flamejante.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/disparada_flamejante_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/disparada_veloz.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/disparada_veloz_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/enraizar.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/enraizar_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/escamas_escorregadias.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/escudo_de_espinhos.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/escudo_de_espinhos_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esquiva_bomba.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esquiva_tornado.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esquiva_tornado_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/explosao_venenosa.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/explosao_venenosa_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/investida_da_lanca.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/investida_da_lanca_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/jogada_de_corpo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/jogada_de_corpo_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/latido_feroz.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/mergulho_e_estouro.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/mergulho_e_estouro_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/recolher_no_casco.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/recolher_no_casco_evo.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/salto_felino.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/voo_alto.dart';
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
/// antes de qualquer `BuildContext` existir). Cobre as habilidades dos DOIS botões. A `ability2` chegou a ser dado morto,
/// mas hoje aparece em tela — `IntroOverlay` e `PauseMenuOverlay` mostram nome
/// e descrição dela —, então ficar de fora deixava metade do kit em português
/// dentro do jogo em inglês.
///
/// As formas evoluídas entram com chave própria mesmo quando o texto é igual
/// ao da base: quatro delas (`BradoEvo`, `DisparadaVelozEvo`,
/// `EsquivaTornadoEvo`, `JogadaDeCorpoEvo`) hoje repetem o texto do original,
/// e chave separada deixa diferenciar pelo arb, sem tocar em Dart.
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
    EsporoErrante() => l.abilityName_EsporoErrante,

    // --- Habilidades do botao B (ability2) ---
    BolhaProtetora() => l.abilityName_BolhaProtetora,
    CasuloDeEsporos() => l.abilityName_CasuloDeEsporos,
    CasuloDeEsporosEvo() => l.abilityName_CasuloDeEsporosEvo,
    BolhaProtetoraEvo() => l.abilityName_BolhaProtetoraEvo,
    Brado() => l.abilityName_Brado,
    BradoEvo() => l.abilityName_BradoEvo,
    CascoFechado() => l.abilityName_CascoFechado,
    CascoFechadoEvo() => l.abilityName_CascoFechadoEvo,
    CorrenteEstatica() => l.abilityName_CorrenteEstatica,
    CorrenteEstaticaEvo() => l.abilityName_CorrenteEstaticaEvo,
    DisparadaCongelante() => l.abilityName_DisparadaCongelante,
    DisparadaCongelanteEvo() => l.abilityName_DisparadaCongelanteEvo,
    DisparadaFlamejante() => l.abilityName_DisparadaFlamejante,
    DisparadaFlamejanteEvo() => l.abilityName_DisparadaFlamejanteEvo,
    DisparadaVeloz() => l.abilityName_DisparadaVeloz,
    DisparadaVelozEvo() => l.abilityName_DisparadaVelozEvo,
    Enraizar() => l.abilityName_Enraizar,
    EnraizarEvo() => l.abilityName_EnraizarEvo,
    EscamasEscorregadias() => l.abilityName_EscamasEscorregadias,
    EscudoDeEspinhos() => l.abilityName_EscudoDeEspinhos,
    EscudoDeEspinhosEvo() => l.abilityName_EscudoDeEspinhosEvo,
    EsquivaBomba() => l.abilityName_EsquivaBomba,
    EsquivaTornado() => l.abilityName_EsquivaTornado,
    EsquivaTornadoEvo() => l.abilityName_EsquivaTornadoEvo,
    ExplosaoVenenosa() => l.abilityName_ExplosaoVenenosa,
    ExplosaoVenenosaEvo() => l.abilityName_ExplosaoVenenosaEvo,
    InvestidaDaLanca() => l.abilityName_InvestidaDaLanca,
    InvestidaDaLancaEvo() => l.abilityName_InvestidaDaLancaEvo,
    JogadaDeCorpo() => l.abilityName_JogadaDeCorpo,
    JogadaDeCorpoEvo() => l.abilityName_JogadaDeCorpoEvo,
    LatidoFeroz() => l.abilityName_LatidoFeroz,
    MergulhoEEstouro() => l.abilityName_MergulhoEEstouro,
    MergulhoEEstouroEvo() => l.abilityName_MergulhoEEstouroEvo,
    RecolherNoCasco() => l.abilityName_RecolherNoCasco,
    RecolherNoCascoEvo() => l.abilityName_RecolherNoCascoEvo,
    SaltoFelino() => l.abilityName_SaltoFelino,
    VooAlto() => l.abilityName_VooAlto,

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
    EsporoErrante() => l.abilityDesc_EsporoErrante,

    // --- Habilidades do botao B (ability2) ---
    BolhaProtetora() => l.abilityDesc_BolhaProtetora,
    CasuloDeEsporos() => l.abilityDesc_CasuloDeEsporos,
    CasuloDeEsporosEvo() => l.abilityDesc_CasuloDeEsporosEvo,
    BolhaProtetoraEvo() => l.abilityDesc_BolhaProtetoraEvo,
    Brado() => l.abilityDesc_Brado,
    BradoEvo() => l.abilityDesc_BradoEvo,
    CascoFechado() => l.abilityDesc_CascoFechado,
    CascoFechadoEvo() => l.abilityDesc_CascoFechadoEvo,
    CorrenteEstatica() => l.abilityDesc_CorrenteEstatica,
    CorrenteEstaticaEvo() => l.abilityDesc_CorrenteEstaticaEvo,
    DisparadaCongelante() => l.abilityDesc_DisparadaCongelante,
    DisparadaCongelanteEvo() => l.abilityDesc_DisparadaCongelanteEvo,
    DisparadaFlamejante() => l.abilityDesc_DisparadaFlamejante,
    DisparadaFlamejanteEvo() => l.abilityDesc_DisparadaFlamejanteEvo,
    DisparadaVeloz() => l.abilityDesc_DisparadaVeloz,
    DisparadaVelozEvo() => l.abilityDesc_DisparadaVelozEvo,
    Enraizar() => l.abilityDesc_Enraizar,
    EnraizarEvo() => l.abilityDesc_EnraizarEvo,
    EscamasEscorregadias() => l.abilityDesc_EscamasEscorregadias,
    EscudoDeEspinhos() => l.abilityDesc_EscudoDeEspinhos,
    EscudoDeEspinhosEvo() => l.abilityDesc_EscudoDeEspinhosEvo,
    EsquivaBomba() => l.abilityDesc_EsquivaBomba,
    EsquivaTornado() => l.abilityDesc_EsquivaTornado,
    EsquivaTornadoEvo() => l.abilityDesc_EsquivaTornadoEvo,
    ExplosaoVenenosa() => l.abilityDesc_ExplosaoVenenosa,
    ExplosaoVenenosaEvo() => l.abilityDesc_ExplosaoVenenosaEvo,
    InvestidaDaLanca() => l.abilityDesc_InvestidaDaLanca,
    InvestidaDaLancaEvo() => l.abilityDesc_InvestidaDaLancaEvo,
    JogadaDeCorpo() => l.abilityDesc_JogadaDeCorpo,
    JogadaDeCorpoEvo() => l.abilityDesc_JogadaDeCorpoEvo,
    LatidoFeroz() => l.abilityDesc_LatidoFeroz,
    MergulhoEEstouro() => l.abilityDesc_MergulhoEEstouro,
    MergulhoEEstouroEvo() => l.abilityDesc_MergulhoEEstouroEvo,
    RecolherNoCasco() => l.abilityDesc_RecolherNoCasco,
    RecolherNoCascoEvo() => l.abilityDesc_RecolherNoCascoEvo,
    SaltoFelino() => l.abilityDesc_SaltoFelino,
    VooAlto() => l.abilityDesc_VooAlto,

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
