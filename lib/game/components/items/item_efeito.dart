import 'package:creatures_rogue/game/components/effects/sprite_effect.dart';
import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/efeitos_temporarios.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'dart:math';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/aura_pulse_effect.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/map/dungeon_generator.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/items/collectible.dart';
import 'package:creatures_rogue/game/components/items/item_descritor.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'package:flame/components.dart';

/// Item que reage a um EVENTO, em oposição ao [PowerUpType], que só soma num
/// stat na hora da coleta.
///
/// Por que não reaproveitar `Passive` (`creatures/passive.dart`, hoje toda
/// comentada): `Passive` pertence ao `CreatureData`, então troca junto com a
/// criatura ativa. Item pertence ao JOGADOR e persiste na troca — é a mesma
/// distinção que fez `bonusHpItens` existir. Ganchos parecidos, dono
/// diferente; juntar os dois faria o item herdar a regra errada.
///
/// Instâncias são `const` e vivem em [ItemEfeitoRegistry.todos], igual a
/// `Ability`: o item não guarda estado nenhum, quem guarda é o `Player`.
abstract class ItemEfeito implements ItemDescritor {
  const ItemEfeito();

  /// Chave estável do save. NUNCA renomear depois de publicado.
  @override
  String get id;

  @override
  String get spritePath;
  @override
  Color get cor1;
  @override
  Color get cor2;
  @override
  String nome(BuildContext context);
  @override
  String descricao(BuildContext context);

  /// Este efeito pode aparecer em pedestal e loja? `false` = só se ganha por
  /// outra via (as passivas de aposentadoria), mas continua registrado em
  /// [ItemEfeitoRegistry.todos] — é `porId` que reconstrói `player.itens` no
  /// carregamento do save, e um registro separado faria eles desaparecerem ao
  /// recarregar.
  bool get sorteavel => true;

  /// ANTES de qualquer escudo: dispara sempre que o jogador TENTA tomar dano,
  /// mesmo que o golpe seja inteiramente absorvido.
  ///
  /// Separado de [aoTomarDano] de propósito — aquele só roda quando o dano
  /// chega no HP de verdade. Efeito de retaliação quer o primeiro; efeito que
  /// reage a ferimento quer o segundo.
  void aoTentarTomarDano(Player player, double amount) {}

  /// Toda esquiva, com a direção já resolvida.
  void aoEsquivar(Player player, Vector2 direcao) {}

  /// Depois do dano ser resolvido (tipo, redução e escudo já aplicados), e só
  /// se ele realmente passou do escudo e chegou no HP.
  void aoTomarDano(Player player, double danoFinal, CreatureType tipoAtacante) {}

  /// Quando o escudo passivo (a barra derivada da defesa) vai de >0 pra 0.
  /// NÃO dispara pela bolha de habilidade (`shieldHits`) — são dois sistemas
  /// independentes, e a bolha estoura com frequência muito diferente.
  void aoQuebrarEscudo(Player player) {}

  /// Depois da troca, com o `Player` já mutado: [entra] é `player.creatureData`.
  void aoTrocarCriatura(Player player, CreatureData sai, CreatureData entra) {}

  /// Uma criatura entrou no grupo pela PRIMEIRA vez nesta run — trocar de
  /// volta pra uma que já passou por lá não dispara de novo.
  ///
  /// Diferente de [aoTrocarCriatura], que fala de quem está no comando agora:
  /// este é sobre o elenco. Quem chama é
  /// `CreaturesRogueGame._registrarCriaturaUsada`, o único lugar que sabe o
  /// que é novidade.
  void aoUsarCriaturaNova(Player player, CreatureData criatura) {}

  /// O golpe saiu crítico. [alvo] é quem levou — o único gancho que recebe o
  /// inimigo, porque é o único disparado de dentro do `Enemy.takeDamage`.
  void aoCritar(Player player, Enemy alvo) {}

  /// Este item gasta `Player.cargasDeSala`?
  ///
  /// Serve pra duas coisas: a Hud só desenha o contador de cargas quando
  /// alguém as usa, e o `Player` só as ACUMULA nesse caso — senão, achar um
  /// item de carga no quinto andar viria com todas as salas já andadas de
  /// presente.
  bool get usaCargasDeSala => false;

  /// O jogador usou a habilidade do botão B, QUALQUER que seja o tipo dela.
  ///
  /// Dispara junto com [aoEsquivar] e [aoUsarDefesa], não no lugar deles: uma
  /// esquiva chama este E aquele. É o gancho pra efeito que não se importa com
  /// o tipo da habilidade — e é o único que vale pra todas as 34 criaturas,
  /// já que cada uma tem só um tipo de botão B.
  void aoUsarAbility2(Player player) {}

  /// O jogador usou a habilidade DEFENSIVA (`AbilityTipo.defesa`).
  ///
  /// Irmão do [aoEsquivar], que cobre `AbilityTipo.esquiva`: os dois saem do
  /// mesmo `Player.dispararAbility2`, cada um no seu ramo de tipo. Não existe
  /// gancho pra `AbilityTipo.ataque` porque ninguém precisou até agora.
  void aoUsarDefesa(Player player) {}

  void aoAtualizar(Player player, double dt) {}
}

class ItemEfeitoRegistry {
  static const List<ItemEfeito> todos = [
    // --- Passivas de aposentadoria: `sorteavel` false, ver `ItemEfeito`. ---
    RastroFlamejante(),
    CascoReflexivo(),
    BolhaAutonoma(),
    CorrenteReflexa(),
    TornadoResidual(),
    BombaNaEsquiva(),
    SaltoAquatico(),
    BradoReflexo(),
    ReflexoEletrico(),
    ImpetoArdente(),
    PeconhaReflexiva(),
    RetaliacaoEletrica(),
    RastroCongelante(),
    Revezamento(),
    CascaInstavel(),
    Estilhaco(),
    PeleDeCinzas(),
    Couraca(),
    Desesperado(),
    Legado(),
    DiarioDeCampo(),
    EloDoGrupo(),
    Imposto(),
    PedraElemental(CreatureType.fogo),
    PedraElemental(CreatureType.agua),
    PedraElemental(CreatureType.planta),
    PedraElemental(CreatureType.eletrico),
    Sentinela(),
    Recarga(),
    Repulsao(),
    SegundoFolego(),
    Esgotamento(),
    GatilhoFrio(),
    SangueFrio(),
    Bussola(),
  ];

  static ItemEfeito? porId(String id) {
    for (final item in todos) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// Troca de criatura dá dano extra por alguns segundos. Faz a troca virar
/// jogada ofensiva, não só botão de pânico quando a vida acaba.
class Revezamento extends ItemEfeito {
  const Revezamento();

  static const double bonusDano = 0.5;
  static const double duracao = 4.0;

  @override
  String get id => 'revezamento';

  @override
  String get spritePath => 'items/revezamento.png';

  @override
  Color get cor1 => const Color(0xFFFFC66D);

  @override
  Color get cor2 => const Color(0xFF8B3E2F);

  @override
  String nome(BuildContext context) => context.l10n.item_revezamento;

  @override
  String descricao(BuildContext context) => context.l10n.item_revezamentoDesc;

  @override
  void aoTrocarCriatura(Player player, CreatureData sai, CreatureData entra) {
    // `dono: jogador` é obrigatório aqui: a própria troca limpa os efeitos da
    // criatura logo antes de chamar este gancho, então um efeito marcado como
    // `criatura` seria varrido no mesmo instante em que nasce.
    //
    // `danoMult` é estático e compartilhado, então soma e subtração TÊM que
    // vir em par — é o CONTRATO do mixin que garante isso, e por isso
    // `aoIniciar` não repete quando o efeito é só renovado.
    player.aplicarEfeito(
      #revezamento,
      duracao,
      dono: EfeitoDono.jogador,
      aoIniciar: () => Player.danoMult += bonusDano,
      aoTerminar: () => Player.danoMult -= bonusDano,
    );
  }
}

/// Levar dano no HP causa uma explosão em volta do jogador. Escala com
/// `defesa`, o stat que fora disso só alimenta o escudo passivo, E com o
/// tamanho do golpe levado.
///
/// O golpe entra na conta pra separar este item da [PeleDeCinzas], que dispara
/// no mesmo gancho e no mesmo raio: aqui o troco é proporcional — arranhão de
/// contato devolve pouco, pancada de boss devolve muito. Com o dano fixo de
/// antes, os dois eram a mesma jogada com dano de tipo diferente.
class CascaInstavel extends ItemEfeito {
  const CascaInstavel();

  /// Multiplica `danoFinal * defesa`. Mantido em 1,5 de propósito: com a
  /// `defesa` 1 de quase todo o elenco e um golpe comum de 1, o estouro sai
  /// exatamente no valor fixo de antes — o que muda é o topo, não a média.
  static const double coefDano = 5.0;

  @override
  String get id => 'cascaInstavel';
  @override
  String get spritePath => 'items/cascoQuebrado.png';
  @override
  Color get cor1 => Palette.pumpkin;
  @override
  Color get cor2 => Palette.burgundy;
  @override
  String nome(BuildContext context) => context.l10n.item_cascaInstavel;
  @override
  String descricao(BuildContext context) =>
      context.l10n.item_cascaInstavelDesc;

  @override
  void aoTomarDano(Player player, double danoFinal, CreatureType tipoAtacante) {
    player.parent?.add(
      ExplosionHitbox(
        position: player.position.clone(),
        dmg: danoFinal * player.creatureData.stats.defesa * coefDano,
        tipo: player.creatureData.tipo,
        cor2: Palette.laranja,
      ),
    );
  }
}

/// O escudo passivo chegando a zero estoura em projéteis radiais. Transforma
/// perder o escudo em algo que o jogador quer que aconteça de vez em quando.
class Estilhaco extends ItemEfeito {
  const Estilhaco();

  static const int qtdProjeteis = 8;
  static const double coefDano = 1.5;

  @override
  String get id => 'estilhaco';
  @override
  String get spritePath => 'items/escudoQuebr.png';
  @override
  Color get cor1 => Palette.azul;
  @override
  Color get cor2 => Palette.azulEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_estilhaco;
  @override
  String descricao(BuildContext context) => context.l10n.item_estilhacoDesc;

  @override
  void aoQuebrarEscudo(Player player) {
    final dano = player.creatureData.stats.ataque * coefDano;
    for (int i = 0; i < qtdProjeteis; i++) {
      final ang = (pi * 2 / qtdProjeteis) * i;
      player.parent?.add(
        Projectile(
          owner: player,
          position: player.position.clone(),
          direction: Vector2(cos(ang), sin(ang)),
          //speed: 70,
          lifeTime: 1.0,
          dmg: dano,
          sprPath: 'projeteis/proj2.png',
          cor1: Palette.azul,
          cor2: Palette.branco,
          tipo: player.creatureData.tipo,
          radius: 3,
        ),
      );
    }
  }
}

/// Queima continuamente quem estiver perto. Premia jogar no aperto, o oposto
/// do que o resto do kit defensivo pede.
///
/// AURA, e não contra-ataque: antes disparava em `aoTomarDano`, o MESMO gancho
/// e o MESMO raio da [CascaInstavel], e as duas eram a mesma jogada. Mais que
/// isso, "premia jogar no aperto" não era o que ela fazia — ela premiava levar
/// dano, que é outra coisa. Agora o gatilho é a proximidade, então ficar no
/// meio do bolo basta.
///
/// A cadência sai de um efeito temporário com `EfeitoStack.ignora`, mesmo
/// truque da passiva `RodaDeFogoEvo`: reaplicar não faz nada enquanto vale, o
/// `aoIniciar` queima na hora de armar e o quadro seguinte rearma quando
/// expira. É o jeito de ter tique periódico sem guardar cronômetro, que um
/// [ItemEfeito] `const` não pode.
///
/// O tique roda SEM checar se há inimigo por perto, de propósito: o pulso do
/// anel (ver `AuraPulseEffect`) é o que mostra o alcance, e ele precisa
/// aparecer antes de o inimigo chegar pra o jogador poder se posicionar. O
/// custo é varrer a lista de inimigos uma vez a cada [intervalo] em sala
/// vazia, o que não aparece em lugar nenhum.
class PeleDeCinzas extends ItemEfeito {
  const PeleDeCinzas();

  static const double alcance = 24.0;

  /// Segundos entre uma queimada e a próxima.
  ///
  /// Folgado porque a queimadura NÃO acumula (`Dot.criar`: `acumula: false`,
  /// teto de 3 tiques de 2 de dano a cada 0,67s). Reaplicar só recarrega o que
  /// falta, então um intervalo curto manteria o inimigo encostado queimando
  /// sem parar — com 2 tiques a cada 2s o teto é 2 de dano por segundo, e
  /// esse é o número pra mexer se ficar fraco ou forte demais.
  static const double intervalo = 1.0;
  static const int ticks = 1;

  @override
  String get id => 'peleDeCinzas';
  @override
  String get spritePath => 'items/peleFogo.png';
  @override
  Color get cor1 => Palette.laranja;
  @override
  Color get cor2 => Palette.vermelho;
  @override
  String nome(BuildContext context) => context.l10n.item_peleDeCinzas;
  @override
  String descricao(BuildContext context) => context.l10n.item_peleDeCinzasDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    player.aplicarEfeito(
      #peleDeCinzasAura,
      intervalo,
      stack: EfeitoStack.ignora,
      // `aoIniciar`, não `aoTerminar`: pulsa e queima no instante em que o
      // efeito arma. No `aoTerminar` o primeiro pulso só sairia [intervalo]
      // depois, e a aura leria como desligada até lá.
      aoIniciar: () => _queimarPerto(player),
    );
  }

  void _queimarPerto(Player player) {
    // Anel com o [alcance] de verdade, não um número visual escolhido à parte:
    // a aura acertava sem dizer onde começava e onde acabava.
    player.parent?.add(
      AuraPulseEffect(
        position: player.position.clone(),
        raio: alcance,
        cor1: Palette.pumpkin,
        cor2: Palette.vermelho,
      ),
    );

    final inimigos =
        player.parent?.children.whereType<Enemy>() ?? const <Enemy>[];
    for (final inimigo in inimigos) {
      if (inimigo.position.distanceTo(player.position) <= alcance) {
        inimigo.applyDot(DotKind.queimadura, ticks);
      }
    }
  }
}

/// Escudo cheio dá dano extra. Par de [Desesperado]: os dois no mesmo run
/// puxam pra lados opostos, que é o ponto.
///
/// O efeito é reaplicado a cada quadro com duração curta em vez de ligado e
/// desligado na mão: [ItemEfeito] é `const` e não pode guardar "já apliquei",
/// e o contrato do mixin garante que `aoTerminar` roda exatamente uma vez
/// quando a renovação para. O custo é o bônus sumir [janela] depois de a
/// condição deixar de valer, não no mesmo quadro.
class Couraca extends ItemEfeito {
  const Couraca();

  static const double bonusDano = 0.25;
  static const double janela = 0.2;

  @override
  String get id => 'couraca';
  @override
  String get spritePath => 'items/armor.png';
  @override
  Color get cor1 => Palette.indigo;
  @override
  Color get cor2 => Palette.azulEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_couraca;
  @override
  String descricao(BuildContext context) => context.l10n.item_couracaDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    if (player.shieldMax <= 0 || player.shield < player.shieldMax) return;
    player.aplicarEfeito(
      #couraca,
      janela,
      dono: EfeitoDono.jogador,
      aoIniciar: () => Player.danoMult += bonusDano,
      aoTerminar: () => Player.danoMult -= bonusDano,
    );
  }
}

/// Sem escudo nenhum: mais velocidade e mais cadência. Par de [Couraca].
class Desesperado extends ItemEfeito {
  const Desesperado();

  static const double bonusVel = 0.25;
  static const double fatorCadencia = 0.8;
  static const double janela = 0.2;

  @override
  String get id => 'desesperado';
  @override
  String get spritePath => 'items/desespero.png';
  @override
  Color get cor1 => Palette.verde;
  @override
  Color get cor2 => Palette.verdeEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_desesperado;
  @override
  String descricao(BuildContext context) => context.l10n.item_desesperadoDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    if (player.shield > 0) return;
    player.aplicarEfeito(
      #desesperado,
      janela,
      dono: EfeitoDono.jogador,
      aoIniciar: () {
        player.velMult += bonusVel;
        player.cdMult *= fatorCadencia;
      },
      aoTerminar: () {
        player.velMult -= bonusVel;
        player.cdMult /= fatorCadencia;
      },
    );
  }
}

/// A criatura que SAI deixa uma poça do elemento dela no chão. Dá um motivo
/// pra trocar fora de emergência, e o efeito muda conforme o grupo.
class Legado extends ItemEfeito {
  const Legado();

  static const double coefDano = 1.6;
  static const double duracao = 4.0;

  @override
  String get id => 'legado';
  @override
  String get spritePath => 'items/capsula.png';
  @override
  Color get cor1 => Palette.verde;
  @override
  Color get cor2 => Palette.roxoEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_legado;
  @override
  String descricao(BuildContext context) => context.l10n.item_legadoDesc;

  @override
  void aoTrocarCriatura(Player player, CreatureData sai, CreatureData entra) {
    final (sprite, dot) = switch (sai.tipo) {
      CreatureType.fogo => ('projeteis/fogo.png', DotKind.queimadura),
      CreatureType.planta => ('projeteis/folha.png', DotKind.veneno),
      CreatureType.agua => ('projeteis/bolha.png', null),
      CreatureType.eletrico => ('projeteis/raio.png', null),
      CreatureType.neutro => ('projeteis/nuvem.png', null),
    };

    
    for(var i=-1;i<=1;i++){
      for(var j=-1;j<=1;j++){
      player.parent?.add(
        Projectile(
          owner: player,
          position: player.position.clone() + Vector2(i*16,j*16),
          direction: Vector2.zero(),
          speed: 0,
          lifeTime: duracao,
          dmg: sai.stats.ataque * coefDano,
          sprPath: sprite,
          cor1: sai.corClara,
          cor2: sai.corEscura,
          tipo: sai.tipo,
          radius: 8,
          atravessa: 100,
          dotKind: dot,
          dotTicks: 4,
        ),
      );
    }
    }
    
  }
}

// ---------------------------------------------------------------------------
// Passivas de aposentadoria (ver [PassivasAposentadoria]). Vêm das classes em
// `creatures/passives/`, que nasceram como `Passive` — ligadas ao
// `CreatureData` e portanto mortas na troca de criatura. Aqui elas são do
// JOGADOR e permanentes, que é o que a aposentadoria exige: a criatura vai
// embora e o bônus fica.
//
// `sorteavel => false` nas seis: não aparecem em pedestal nem em loja.
//
// `spritePath` e cores existem só pra satisfazer a interface — nenhuma delas
// chega a ser instanciada como coletável.
// ---------------------------------------------------------------------------

/// Roedor de Fogo. Toda esquiva termina numa explosão de fogo no ponto de
/// chegada.
class RastroFlamejante extends ItemEfeito {
  const RastroFlamejante({this.coef = 0.5});

  final double coef;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'rastroFlamejante';
  @override
  String get spritePath => 'items/capsula.png';
  @override
  Color get cor1 => Palette.vermelho;
  @override
  Color get cor2 => Palette.laranja;
  @override
  String nome(BuildContext context) => context.l10n.passiva_rastroFlamejante;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_rastroFlamejanteDesc;

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    final dano = player.creatureData.stats.ataque * coef;
    // No FIM da esquiva, não no início: a explosão marca onde ele chegou.
    // Efeito temporário em vez do `Future.delayed` que a `Passive` usava —
    // este respeita pausa e é limpo na troca de criatura.
    player.aplicarEfeito(
      #rastroFlamejante,
      player.dodgeIframeDuration,
      aoTerminar: () => player.parent?.add(
        ExplosionHitbox(
          position: player.position.clone(),
          dmg: dano,
          cor2: Palette.laranja,
          tipo: player.creatureData.tipo,
          dotKind: DotKind.queimadura,
          dotTicks: 5,
        ),
      ),
    );
  }
}

/// Tartaruga de Planta. Durante os i-frames da esquiva, reflete projéteis.
class CascoReflexivo extends ItemEfeito {
  const CascoReflexivo();

  @override
  bool get sorteavel => false;
  @override
  String get id => 'cascoReflexivo';
  @override
  String get spritePath => 'items/casco.png';
  @override
  Color get cor1 => Palette.verde;
  @override
  Color get cor2 => Palette.verdeEsc;
  @override
  String nome(BuildContext context) => context.l10n.passiva_cascoReflexivo;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_cascoReflexivoDesc;

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    player.aplicarEfeito(
      #cascoReflexivo,
      player.dodgeIframeDuration,
      aoIniciar: () => player.refleteProjetil = true,
      aoTerminar: () => player.refleteProjetil = false,
    );
  }
}

/// Sapo de Água. Sem apanhar por um tempo, forma sozinho um escudo de um
/// golpe.
class BolhaAutonoma extends ItemEfeito {
  const BolhaAutonoma({this.tempoParaFormar = 5.0});

  final double tempoParaFormar;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'bolhaAutonoma';
  @override
  String get spritePath => 'items/escudo.png';
  @override
  Color get cor1 => Palette.indigo;
  @override
  Color get cor2 => Palette.royal;
  @override
  String nome(BuildContext context) => context.l10n.passiva_bolhaAutonoma;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_bolhaAutonomaDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    if (player.shieldHits > 0) return;
    if (player.tempoSemApanhar < tempoParaFormar) return;
    player.adicionarEscudoPermanente(1);
  }
}

/// Ave Elétrica. Todo golpe que o jogador TENTA tomar solta uma descarga
/// atordoante em volta — inclusive os que o escudo come.
class CorrenteReflexa extends ItemEfeito {
  const CorrenteReflexa({this.coef = 1.0, this.duracaoStun = 1.5});

  final double coef;
  final double duracaoStun;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'correnteReflexa';
  @override
  String get spritePath => 'items/capsula.png';
  @override
  Color get cor1 => Palette.amarelo;
  @override
  Color get cor2 => Palette.laranja;
  @override
  String nome(BuildContext context) => context.l10n.passiva_correnteReflexa;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_correnteReflexaDesc;

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(
      ExplosionHitbox(
        position: player.position.clone(),
        dmg: player.creatureData.stats.ataque * coef,
        stunDuration: duracaoStun,
        cor1: Palette.amarelo,
        cor2: Palette.laranja,
      ),
    );
  }
}

/// Tornado de Fogo. Toda esquiva deixa um tornado no ponto de partida.
class TornadoResidual extends ItemEfeito {
  const TornadoResidual({this.coef = 0.5});

  final double coef;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'tornadoResidual';
  @override
  String get spritePath => 'items/capsula.png';
  @override
  Color get cor1 => Palette.vermelho;
  @override
  Color get cor2 => Palette.laranja;
  @override
  String nome(BuildContext context) => context.l10n.passiva_tornadoResidual;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_tornadoResidualDesc;

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    player.parent?.add(
      Projectile(
        owner: player,
        position: player.position.clone(),
        direction: direcao,
        movimento: ProjetilMovimento.espiral,
        speed: 10,
        velAngular: 4.0,
        lifeTime: 3,
        dmg: player.creatureData.stats.ataque * coef,
        sprPath: 'projeteis/tornado.png',
        cor1: Palette.vermelho,
        cor2: Palette.laranja,
        tipo: player.creatureData.tipo,
        radius: 8,
        atravessa: 10,
      ),
    );
  }
}

/// Bomba de Fogo. Toda esquiva larga uma bomba pra trás, se houver estoque.
class BombaNaEsquiva extends ItemEfeito {
  const BombaNaEsquiva();

  @override
  bool get sorteavel => false;
  @override
  String get id => 'bombaNaEsquiva';
  @override
  String get spritePath => 'items/bomb.png';
  @override
  Color get cor1 => Palette.cinza;
  @override
  Color get cor2 => Palette.cinzaEsc;
  @override
  String nome(BuildContext context) => context.l10n.passiva_bombaNaEsquiva;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_bombaNaEsquivaDesc;

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    player.placeBomb(-direcao);
  }
}

/// Cobra de Água. A esquiva termina num respingo que empurra quem está perto.
class SaltoAquatico extends ItemEfeito {
  const SaltoAquatico({this.coef = 0.4});

  final double coef;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'saltoAquatico';
  @override
  String get spritePath => 'items/gelo.png';
  @override
  Color get cor1 => Palette.azul;
  @override
  Color get cor2 => Palette.royal;
  @override
  String nome(BuildContext context) => context.l10n.passiva_saltoAquatico;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_saltoAquaticoDesc;

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    final dano = player.creatureData.stats.ataque * coef;
    player.aplicarEfeito(
      #saltoAquatico,
      player.dodgeIframeDuration,
      aoTerminar: () => player.parent?.add(
        ExplosionHitbox(
          position: player.position.clone(),
          dmg: dano,
          knockback: 30,
          size: Vector2(28, 28),
          cor1: Palette.azul,
          cor2: Palette.royal,
          tipo: player.creatureData.tipo,
        ),
      ),
    );
  }
}

/// Urso de Planta. Todo golpe que o jogador TENTA tomar empurra tudo em volta
/// pra longe — o eco da habilidade `Brado` dele.
class BradoReflexo extends ItemEfeito {
  const BradoReflexo({this.coef = 0.25, this.empurrao = 100});

  final double coef;
  final double empurrao;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'bradoReflexo';
  @override
  String get spritePath => 'items/fruta.png';
  @override
  Color get cor1 => Palette.verde;
  @override
  Color get cor2 => Palette.marromEsc;
  @override
  String nome(BuildContext context) => context.l10n.passiva_bradoReflexo;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_bradoReflexoDesc;

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(
      ExplosionHitbox(
        position: player.position.clone(),
        dmg: player.creatureData.stats.ataque * coef,
        knockback: empurrao,
        size: Vector2(48, 48),
        tipo: player.creatureData.tipo,
      ),
    );
  }
}

/// Grilo Elétrico. A esquiva recarrega bem mais rápido, mas percorre menos
/// distância.
///
/// Única das passivas que não é gancho de evento: são dois multiplicadores
/// permanentes. Reafirmados todo quadro em [aoAtualizar], por ATRIBUIÇÃO e não
/// multiplicação — assim não há par de aplicar/desfazer pra manter, o efeito
/// volta sozinho depois de um `trocarCriatura` (que zera estado de combate) e
/// sobrevive ao carregamento do save sem precisar de um gancho "ao ganhar".
class ReflexoEletrico extends ItemEfeito {
  const ReflexoEletrico({this.multCooldown = 0.6, this.multDistancia = 0.8});

  final double multCooldown;
  final double multDistancia;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'reflexoEletrico';
  @override
  String get spritePath => 'items/capsula.png';
  @override
  Color get cor1 => Palette.amarelo;
  @override
  Color get cor2 => Palette.marromEsc;
  @override
  String nome(BuildContext context) => context.l10n.passiva_reflexoEletrico;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_reflexoEletricoDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    player.dodgeCdMult = multCooldown;
    player.dodgeDistMult = multDistancia;
  }
}

/// Roda de Fogo. Na velocidade máxima, o corpo do jogador machuca quem
/// encostar — a assinatura da criatura virando permanente, sem a imunidade a
/// contato que ela tinha (essa fica só com quem está pilotando a Roda).
///
/// Escreve em `Player.danoDeContato`, o mesmo campo que a passiva de criatura
/// [RodaDeFogo] usa. Os dois convivem: os itens rodam ANTES de
/// `creatureData.passive` no `Player.update`, então jogando DE Roda de Fogo o
/// valor da criatura vence (é maior). Com qualquer outra criatura, vale este.
class ImpetoArdente extends ItemEfeito {
  const ImpetoArdente({this.limiarVelocidade = 0.9, this.coefDano = 0.6});

  /// Fração de `Player.maxSpeed` a partir da qual conta como máxima. Mais
  /// exigente que o da criatura (0,75): aqui não há o freio de ter que jogar
  /// sem habilidade 1 pra compensar.
  final double limiarVelocidade;

  final double coefDano;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'impetoArdente';
  @override
  String get spritePath => 'items/capsula.png';
  @override
  Color get cor1 => Palette.laranja;
  @override
  Color get cor2 => Palette.vermelho;
  @override
  String nome(BuildContext context) => context.l10n.passiva_impetoArdente;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_impetoArdenteDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    final maxima = player.maxSpeed;
    final naMaxima =
        maxima > 0 && player.velocity.length >= maxima * limiarVelocidade;

    // Atribui nos DOIS casos. Zerar é obrigatório: com uma criatura que não
    // tem passiva, ninguém mais escreve neste campo, e sem o `else` o dano de
    // contato ficaria ligado pra sempre depois da primeira vez que o jogador
    // encostasse na velocidade máxima.
    //
    // Não atropela a Roda de Fogo porque a passiva da criatura roda DEPOIS
    // dos itens no `Player.update` e reescreve o campo com a palavra final.
    player.danoDeContato = naMaxima
        ? player.creatureData.stats.ataque * coefDano
        : 0.0;
  }
}

/// Slime de Planta. Levar dano solta uma nuvem de veneno em volta — quem te
/// encostou sai envenenado.
///
/// `aoTentarTomarDano` não recebe QUEM atacou, então o veneno sai como área em
/// volta do jogador em vez de ir no agressor. Na prática dá no mesmo: quem
/// acabou de te acertar está encostado em você.
class PeconhaReflexiva extends ItemEfeito {
  const PeconhaReflexiva({this.coef = 0.3, this.dotTicks = 4});

  final double coef;
  final int dotTicks;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'peconhaReflexiva';
  @override
  String get spritePath => 'items/fruta.png';
  @override
  Color get cor1 => Palette.verde;
  @override
  Color get cor2 => Palette.verdeEsc;
  @override
  String nome(BuildContext context) => context.l10n.passiva_peconhaReflexiva;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_peconhaReflexivaDesc;

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(
      ExplosionHitbox(
        position: player.position.clone(),
        dmg: player.creatureData.stats.ataque * coef,
        size: Vector2(32, 32),
        cor1: Palette.verde,
        cor2: Palette.verdeEsc,
        tipo: player.creatureData.tipo,
        dotKind: DotKind.veneno,
        dotTicks: dotTicks,
      ),
    );
  }
}

/// Ouriço Elétrico. Levar dano solta uma descarga que atordoa em volta.
///
/// Primo da `CorrenteReflexa` (Ave Elétrica), e de propósito: a diferença é
/// que esta troca alcance por atordoamento mais longo, que é o jogo do Ouriço
/// — ele é lento e precisa que o inimigo pare, não que se afaste.
class RetaliacaoEletrica extends ItemEfeito {
  const RetaliacaoEletrica({this.coef = 0.5, this.duracaoStun = 2.0});

  final double coef;
  final double duracaoStun;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'retaliacaoEletrica';
  @override
  String get spritePath => 'items/capsula.png';
  @override
  Color get cor1 => Palette.amarelo;
  @override
  Color get cor2 => Palette.cinzaEsc;
  @override
  String nome(BuildContext context) => context.l10n.passiva_retaliacaoEletrica;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_retaliacaoEletricaDesc;

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(
      ExplosionHitbox(
        position: player.position.clone(),
        dmg: player.creatureData.stats.ataque * coef,
        stunDuration: duracaoStun,
        size: Vector2(24, 24),
        cor1: Palette.amarelo,
        cor2: Palette.laranja,
        tipo: player.creatureData.tipo,
      ),
    );
  }
}

/// Pinguim de Água. Toda esquiva deixa uma poça de gelo no ponto de partida,
/// que lentifica quem passar.
///
/// No ponto de PARTIDA, não no de chegada (ao contrário do `RastroFlamejante`
/// e do `SaltoAquatico`): a poça serve pra atrasar quem está te perseguindo, e
/// pra isso ela tem que ficar atrás.
class RastroCongelante extends ItemEfeito {
  const RastroCongelante({
    this.lentidaoDuracao = 2.5,
    this.lentidaoFator = 0.5,
    this.duracaoPoca = 3.0,
  });

  final double lentidaoDuracao;
  final double lentidaoFator;
  final double duracaoPoca;

  @override
  bool get sorteavel => false;
  @override
  String get id => 'rastroCongelante';
  @override
  String get spritePath => 'items/gelo.png';
  @override
  Color get cor1 => Palette.azul;
  @override
  Color get cor2 => Palette.royal;
  @override
  String nome(BuildContext context) => context.l10n.passiva_rastroCongelante;
  @override
  String descricao(BuildContext context) =>
      context.l10n.passiva_rastroCongelanteDesc;

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    player.parent?.add(
      Projectile(
        owner: player,
        position: player.position.clone(),
        direction: Vector2.zero(),
        speed: 0,
        dmg: 0,
        kbForce: 0,
        sprPath: 'projeteis/bolaGrande.png',
        cor1: Palette.royal,
        cor2: Palette.azul,
        tipo: player.creatureData.tipo,
        lentidaoDuracao: lentidaoDuracao,
        lentidaoFator: lentidaoFator,
        atravessa: 100,
        size: Vector2(24, 24),
        lifeTime: duracaoPoca,
        radius: 12,
        playSfx: false,
      ),
    );
  }
}

/// Qual passiva cada criatura entrega ao se aposentar.
///
/// Este mapa É a pool de aposentadoria: criatura fora dele não acumula a
/// segunda contagem de XP nem se aposenta, porque não haveria o que entregar.
/// Cresce sozinho conforme novas passivas forem escritas — não existe uma
/// segunda lista pra manter em sincronia.
///
/// Cada criatura NOVA que passa pelo grupo nesta run deixa dano permanente.
///
/// Paga por ROTAÇÃO, e é o único item que faz isso: o resto do acervo premia
/// ficar bom no que você já tem, e este premia experimentar. Combina com a
/// sala da escada (`recrutarCriaturaSelvagem`) e com o consumível MAPA, as
/// duas vias de entrar gente no grupo no meio da run.
///
/// O bônus é concedido UMA vez, no momento em que a criatura entra, e não
/// recalculado por quadro. Isso importa: `Player.danoMult` é estático e vai
/// pro save, então somar aqui é um ganho permanente de verdade, gravado como
/// tal — o oposto das janelas de [Couraca]/[Desesperado], que o
/// `_salvarProgresso` tem que derrubar antes da foto justamente porque NÃO
/// são permanentes.
///
/// A primeira criatura da run não paga: `startRun` registra ela antes de os
/// itens existirem. Na prática o item conta da segunda em diante, o que é o
/// que ele promete.
class DiarioDeCampo extends ItemEfeito {
  const DiarioDeCampo();

  /// Quanto cada criatura nova acrescenta em `Player.danoMult`. Mesma ordem
  /// de grandeza do upgrade de dano do pedestal (0,15), um pouco abaixo
  /// porque este pode repetir até o limite do elenco.
  static const double bonusPorCriatura = 0.10;

  @override
  String get id => 'diarioDeCampo';
  @override
  String get spritePath => 'items/diario.png';
  @override
  Color get cor1 => Palette.bege;
  @override
  Color get cor2 => Palette.marromEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_diarioDeCampo;
  @override
  String descricao(BuildContext context) =>
      context.l10n.item_diarioDeCampoDesc;

  @override
  void aoUsarCriaturaNova(Player player, CreatureData criatura) {
    Player.danoMult += bonusPorCriatura;
  }
}

/// Cada companheira viva além da que está no comando dá dano.
///
/// Recompensa NÃO perder ninguém — hoje uma criatura caída só tira opções, e
/// nenhum item falava disso. Perder a segunda companheira derruba o bônus na
/// hora, então o item transforma o grupo num número pra proteger.
///
/// Derivado, não permanente: escreve em `Player.danoMultDerivado`, que é
/// reconstruído a cada quadro. Por isso o valor sobe quando alguém é
/// recrutado e desce quando alguém cai, sem nada pra desfazer.
class EloDoGrupo extends ItemEfeito {
  const EloDoGrupo();

  /// Por companheira viva fora da ativa. Com os 3 slots do grupo, o teto é
  /// duas companheiras — ou seja, +0,30 no máximo.
  static const double bonusPorCompanheira = 0.15;

  @override
  String get id => 'eloDoGrupo';
  @override
  String get spritePath => 'items/elos.png';
  @override
  Color get cor1 => Palette.jade;
  @override
  Color get cor2 => Palette.verdeEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_eloDoGrupo;
  @override
  String descricao(BuildContext context) => context.l10n.item_eloDoGrupoDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    final jogo = player.game;
    if (jogo is! CreaturesRogueGame) return;

    // Conta os slots ocupados: `pocketarSlotAtivo` esvazia o slot de quem cai
    // (nada neste jogo revive), então "slot ocupado" já é "criatura viva".
    final vivas = jogo.companionCreatures.where((c) => c != null).length;
    if (vivas <= 1) return;

    Player.danoMultDerivado += (vivas - 1) * bonusPorCompanheira;
  }
}

/// Moeda no bolso dá dano. Gastar na loja enfraquece.
///
/// Põe a loja em tensão com o combate: até agora guardar moeda era só esperar
/// pelo balcão certo, e o custo de comprar era zero. Com este item, cada
/// compra é uma troca de força imediata por um item.
///
/// Derivado a cada quadro em `Player.danoMultDerivado`, então o bônus cai no
/// mesmo instante em que o balcão cobra.
class Imposto extends ItemEfeito {
  const Imposto();

  static const double bonusPorMoeda = 0.02;

  /// Teto de propósito: moeda não tem limite de acúmulo (ver `CoinPickup`,
  /// "não tem teto útil"), e sem travar aqui uma run de acúmulo viraria dano
  /// infinito. 25 moedas batem no teto, e os balcões mais caros da loja
  /// custam 20 — então o teto fica logo acima do que o jogador de fato
  /// carrega.
  static const double bonusMaximo = 0.50;

  @override
  String get id => 'imposto';
  @override
  String get spritePath => 'items/saco.png';
  @override
  Color get cor1 => Palette.amarelo;
  @override
  Color get cor2 => Palette.marromEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_imposto;
  @override
  String descricao(BuildContext context) => context.l10n.item_impostoDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    Player.danoMultDerivado +=
        (player.coins * bonusPorMoeda).clamp(0.0, bonusMaximo);
  }
}

/// Dano cresce conforme a energia esvazia — os últimos tiros da rajada são os
/// que doem.
///
/// O caminho INVERSO do que parece natural, e de propósito. Energia é o
/// tamanho da rajada (teto 10, regenera 5/s e pausa 0,3s depois de cada tiro,
/// ver `AbilityUser`), então "energia cheia" quer dizer "você ainda não
/// atirou". Um bônus atrelado à energia cheia valeria só no primeiro tiro e
/// sumiria no segundo — premiaria não atirar.
///
/// Atrelado ao esvaziamento, vira decisão: a pausa de regeneração pune quem só
/// martela o botão, então ou você para cedo e mantém a cadência, ou desce até o
/// fundo do pente atrás do dano e engole a espera.
class Esgotamento extends ItemEfeito {
  const Esgotamento();

  /// Dano extra com a energia no zero. No meio do pente rende metade disso —
  /// a escala é linear em cima de `energiaFracao`.
  static const double bonusMaximo = 0.60;

  @override
  String get id => 'esgotamento';
  @override
  String get spritePath => 'items/esgotamento.png';
  @override
  Color get cor1 => Palette.laranja;
  @override
  Color get cor2 => Palette.marromEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_esgotamento;
  @override
  String descricao(BuildContext context) => context.l10n.item_esgotamentoDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    Player.danoMultDerivado += (1 - player.energiaFracao) * bonusMaximo;
  }
}

/// Crítico atordoa o alvo.
///
/// Transforma crítico de "número maior" em controle: com 5% de chance base ele
/// é raro o bastante pra o atordoamento não trivializar a sala, e a sinergia
/// com o [SangueFrio] — que sobe a chance quando o azar se acumula — é
/// intencional.
class GatilhoFrio extends ItemEfeito {
  const GatilhoFrio();

  static const double duracaoStun = 0.8;

  @override
  String get id => 'gatilhoFrio';
  @override
  String get spritePath => 'items/gatilhoFrio.png';
  @override
  Color get cor1 => Palette.azul;
  @override
  Color get cor2 => Palette.royal;
  @override
  String nome(BuildContext context) => context.l10n.item_gatilhoFrio;
  @override
  String descricao(BuildContext context) => context.l10n.item_gatilhoFrioDesc;

  @override
  void aoCritar(Player player, Enemy alvo) {
    alvo.applyStun(duracaoStun);
  }
}

/// Cada golpe sem crítico aumenta a chance do próximo. O crítico zera a
/// conta.
///
/// Mata a variância, que é o problema real de apostar em crítico numa run
/// curta: com 5% de base, uma sequência de azar significa que o investimento
/// inteiro não rendeu nada. Aqui o azar vira a própria garantia.
///
/// A contagem (`Player.golpesSemCrit`) é mantida onde o sorteio acontece, em
/// `Enemy.takeDamage` — este item só lê. E o bônus sai por
/// `Player.critChanceDerivada`, reconstruído a cada quadro, então ele nunca é
/// gravado no save nem se soma em cima de si mesmo.
class SangueFrio extends ItemEfeito {
  const SangueFrio();

  /// Pontos percentuais por golpe sem crítico.
  static const double porGolpe = 4.0;

  /// Teto do acúmulo. Com a base de 5%, dez golpes sem crítico levam a chance
  /// pra perto de 45% — alto, mas só depois de um azar que valha compensar.
  static const double teto = 40.0;

  @override
  String get id => 'sangueFrio';
  @override
  String get spritePath => 'items/sangueFrio.png';
  @override
  Color get cor1 => Palette.royal;
  @override
  Color get cor2 => Palette.azulEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_sangueFrio;
  @override
  String descricao(BuildContext context) => context.l10n.item_sangueFrioDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    player.critChanceDerivada += (player.golpesSemCrit * porGolpe).clamp(
      0.0,
      teto,
    );
  }
}

/// Sala de tesouro e loja aparecem no minimapa desde a chegada no andar.
///
/// Item permanente, e não consumível como o MAPA: aquele revela uma vez e
/// acaba, este muda o roteiro de toda a run — você escolhe o caminho sabendo
/// onde estão as duas salas que interessam.
///
/// A sala do BOSS fica de fora de propósito: saber onde ele está tira a única
/// tensão que sobra em explorar um andar já limpo.
///
/// Reafirma a cada quadro em vez de marcar uma vez porque a dungeon é gerada
/// de novo a cada andar. São poucas dezenas de escritas de bool por quadro, e
/// um gancho de "entrou num andar novo" só se pagaria com um segundo item
/// desse tipo.
class Bussola extends ItemEfeito {
  const Bussola();

  @override
  String get id => 'bussola';
  @override
  String get spritePath => 'items/bussola.png';
  @override
  Color get cor1 => Palette.laranja;
  @override
  Color get cor2 => Palette.roxoEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_bussola;
  @override
  String descricao(BuildContext context) => context.l10n.item_bussolaDesc;

  @override
  void aoAtualizar(Player player, double dt) {
    final jogo = player.game;
    if (jogo is! CreaturesRogueGame) return;

    for (final sala in jogo.mapData.values) {
      if (sala.type == RoomType.item || sala.type == RoomType.shop) {
        sala.isRevealed = true;
      }
    }
  }
}

/// Pedra elemental: aumenta o dano de UM elemento.
///
/// Uma classe só, parametrizada pelo [tipo], em vez de quatro quase idênticas:
/// a diferença entre a Pedra de Fogo e a de Água é uma cor, um nome e uma
/// chave de mapa. As quatro instâncias ficam em `ItemEfeitoRegistry.todos`.
///
/// Escreve em `Player.danoElementalDerivado`, e não no `danoMultDerivado`:
/// aquele é global e é lido no ponto do acerto, onde não existe informação de
/// elemento. Quem sabe o elemento do golpe é o `Enemy.takeDamage`, e é lá que
/// o mapa é consultado.
///
/// O bônus pega TUDO daquele elemento, inclusive o dano por tempo: um tique de
/// queimadura chega em `takeDamage` com `tipoAtacante: fogo`.
///
/// AVISO DE BALANCEAMENTO: o elemento dos seus golpes vem da criatura ativa
/// (`creatureData.tipo`), que não muda no meio do combate. Então esta pedra é
/// forte com a criatura certa e **peso morto** com as outras — é um item que
/// premia quem monta o grupo em torno de um elemento. Se isso ficar frustrante
/// demais no teste, o conserto é o bônus valer também pro elemento da criatura
/// ATIVA, seja qual for a pedra; mas aí ela deixa de ser uma escolha.
class PedraElemental extends ItemEfeito {
  const PedraElemental(this.tipo);

  final CreatureType tipo;

  /// Quanto o dano daquele elemento sobe. Generoso de propósito: o item só
  /// vale enquanto a criatura ativa for do elemento certo, então um bônus
  /// tímido o deixaria pior que qualquer `+DANO` de pedestal, que vale sempre.
  static const double bonus = 0.30;

  @override
  String get id => 'pedra_${tipo.name}';

  /// Um desenho por elemento. O arquivo do elétrico é `pedraRaio`, e não
  /// `pedraEletrico` como o resto do enum sugeriria — nome do asset, não do
  /// código.
  @override
  String get spritePath => switch (tipo) {
    CreatureType.fogo => 'items/pedraFogo.png',
    CreatureType.agua => 'items/pedraAgua.png',
    CreatureType.planta => 'items/pedraPlanta.png',
    CreatureType.eletrico => 'items/pedraRaio.png',
    CreatureType.neutro => 'items/pedraFogo.png',
  };

  @override
  Color get cor1 => switch (tipo) {
    CreatureType.fogo => Palette.vermelho,
    CreatureType.agua => Palette.azul,
    CreatureType.planta => Palette.verde,
    CreatureType.eletrico => Palette.amarelo,
    CreatureType.neutro => Palette.cinza,
  };

  @override
  Color get cor2 => switch (tipo) {
    CreatureType.fogo => Palette.laranja,
    CreatureType.agua => Palette.royal,
    CreatureType.planta => Palette.verdeEsc,
    CreatureType.eletrico => Palette.marromEsc,
    CreatureType.neutro => Palette.cinzaEsc,
  };

  /// Nome e descrição por elemento, e não um texto com lacuna: em português
  /// "PEDRA DE FOGO" e "PEDRA ELÉTRICA" não cabem na mesma forma.
  @override
  String nome(BuildContext context) => switch (tipo) {
    CreatureType.fogo => context.l10n.item_pedraFogo,
    CreatureType.agua => context.l10n.item_pedraAgua,
    CreatureType.planta => context.l10n.item_pedraPlanta,
    CreatureType.eletrico => context.l10n.item_pedraEletrico,
    CreatureType.neutro => context.l10n.item_pedraFogo,
  };

  @override
  String descricao(BuildContext context) => switch (tipo) {
    CreatureType.fogo => context.l10n.item_pedraFogoDesc,
    CreatureType.agua => context.l10n.item_pedraAguaDesc,
    CreatureType.planta => context.l10n.item_pedraPlantaDesc,
    CreatureType.eletrico => context.l10n.item_pedraEletricoDesc,
    CreatureType.neutro => context.l10n.item_pedraFogoDesc,
  };

  @override
  void aoAtualizar(Player player, double dt) {
    // Soma, não atribui: duas pedras do mesmo elemento (possível se um dia a
    // pool deixar repetir) acumulam, e o mapa é zerado a cada quadro de
    // qualquer jeito.
    player.danoElementalDerivado[tipo] =
        (player.danoElementalDerivado[tipo] ?? 1.0) + bonus;
  }
}

/// Toda vez que o jogador usa a habilidade do botão B, há chance de algo
/// invisível atacar um inimigo qualquer da sala.
///
/// Vale pra QUALQUER habilidade 2 — defesa, esquiva ou ataque —, e é por isso
/// que o efeito é por CHANCE: amarrado só à defesa, o item seria peso morto
/// nas criaturas cujo botão B é esquiva, que são a maioria.
///
/// Alvo sorteado e não o mais próximo: escolher o mais próximo faria o item
/// premiar quem já estava perto, que é justamente quem menos precisa de ajuda
/// ao se defender. Sorteio também dá pra alcançar quem está atirando de longe.
///
/// Dano do tipo NEUTRO de propósito: sem vantagem nem desvantagem elemental
/// (ver `typeMultiplier`), o item rende igual com qualquer criatura e não vira
/// refém da composição do grupo — o oposto da [PedraElemental], que é uma
/// aposta declarada.
class Sentinela extends ItemEfeito {
  const Sentinela();

  /// Chance por uso do botão B. Não é 100% porque a habilidade 2 tem cooldown
  /// curto em várias criaturas; garantir o golpe transformaria o botão B num
  /// ataque melhor que o A.
  static const double chance = 0.35;

  /// Dano = ataque da criatura x isto. Generoso porque não escala com nada e
  /// só acontece em pouco mais de um a cada três usos.
  static const double coefDano = 1.5;

  @override
  String get id => 'sentinela';
  @override
  String get spritePath => 'items/garrafa.png';
  @override
  Color get cor1 => Palette.indigo;
  @override
  Color get cor2 => Palette.azulEsc;
  @override
  String nome(BuildContext context) => context.l10n.item_sentinela;
  @override
  String descricao(BuildContext context) => context.l10n.item_sentinelaDesc;

  @override
  void aoUsarAbility2(Player player) {
    if (Random().nextDouble() >= chance) return;

    final alvo = _sortearInimigo(player);
    if (alvo == null) return;

    player.parent?.add(
      SpriteEffect(
        position: alvo.position.clone(),
        spritePath: 'effects/summon.png',
        size: Vector2.all(24),
        textureSize: Vector2.all(24),
        corClara: cor1,
        corEscura: cor2,
        corBranco: Palette.branco,
      ),
    );

    alvo.takeDamage(
      player.creatureData.stats.ataque * coefDano,
      tipoAtacante: CreatureType.neutro,
    );
  }

  /// Um inimigo qualquer da sala ATUAL.
  ///
  /// A restrição por sala é a mesma que a mira automática e o item CONGELAR
  /// já usam: todos os inimigos da dungeon existem ao mesmo tempo, então sem
  /// o filtro o golpe acertaria alguém a três salas de distância.
  Enemy? _sortearInimigo(Player player) {
    final sala = player.currentRoom;
    final candidatos = <Enemy>[];

    for (final inimigo in player.parent?.children.whereType<Enemy>() ??
        const <Enemy>[]) {
      if (sala != null &&
          !sala.toAbsoluteRect().contains(
            Offset(inimigo.absolutePosition.x, inimigo.absolutePosition.y),
          )) {
        continue;
      }
      candidatos.add(inimigo);
    }

    if (candidatos.isEmpty) return null;
    return candidatos[Random().nextInt(candidatos.length)];
  }
}

/// Levantar a guarda devolve energia.
///
/// Liga o botão B ao botão A, que hoje não se conversam: a energia é o
/// tamanho da rajada da habilidade 1 (ver `AbilityUser`), e a defesa era tempo
/// parado que não contribuía em nada pro ataque. Com isto, defender no momento
/// certo vira parte do ciclo ofensivo em vez de uma pausa nele.
///
/// Só vale pra criatura de habilidade 2 DEFENSIVA — quem tem esquiva no botão
/// B não tem o que fazer com este item. É o preço de um efeito forte e
/// garantido, sem chance envolvida.
class Recarga extends ItemEfeito {
  const Recarga();

  /// Fração da energia máxima devolvida por uso. Metade é o bastante pra
  /// emendar uma rajada logo depois da defesa, sem tornar a energia irrelevante.
  static const double fracao = 0.5;

  @override
  String get id => 'recarga';
  @override
  String get spritePath => 'items/energyRecover.png';
  @override
  Color get cor1 => Palette.laranja;
  @override
  Color get cor2 => Palette.royal;
  @override
  String nome(BuildContext context) => context.l10n.item_recarga;
  @override
  String descricao(BuildContext context) => context.l10n.item_recargaDesc;

  @override
  void aoUsarDefesa(Player player) {
    player.energia = (player.energia + player.energiaMax * fracao).clamp(
      0.0,
      player.energiaMax,
    );
  }
}

/// Levantar a guarda empurra pra longe quem estiver perto.
///
/// Dano ZERO: a defesa continua sendo defesa, o que muda é que ela passa a
/// COMPRAR ESPAÇO. Resolve o problema de fechar o casco com dois inimigos
/// colados e sair da defesa exatamente onde entrou.
///
/// Mesmo `ExplosionHitbox` de dano zero que o estouro da Bolha Protetora usa —
/// e é por isso que aquele `if (dmg > 0)` do `ExplosionHitbox` importa: sem
/// ele, cada inimigo empurrado ganharia um "0.0" flutuando na cabeça.
class Repulsao extends ItemEfeito {
  const Repulsao();

  static const double empurrao = 110.0;
  static const double raio = 44.0;

  @override
  String get id => 'repulsao';
  @override
  String get spritePath => 'items/repulsao.png';
  @override
  Color get cor1 => Palette.azul;
  @override
  Color get cor2 => Palette.branco;
  @override
  String nome(BuildContext context) => context.l10n.item_repulsao;
  @override
  String descricao(BuildContext context) => context.l10n.item_repulsaoDesc;

  @override
  void aoUsarDefesa(Player player) {
    player.parent?.add(
      ExplosionHitbox(
        position: player.position.clone(),
        dmg: 0,
        knockback: empurrao,
        size: Vector2.all(raio),
        cor1: cor1,
        cor2: cor2,
        tipo: player.creatureData.tipo,
      ),
    );
  }
}

/// Usar a habilidade do botão B cura, gastando cargas ganhas ao explorar.
///
/// Vale pra QUALQUER habilidade 2 — defesa, esquiva ou ataque —, então não
/// depende de a criatura ativa ter o tipo certo, ao contrário da [Recarga] e
/// da [Repulsao].
///
/// O custo é o item inteiro. A primeira versão usava espera em SEGUNDOS, e
/// isso não segurava nada: numa sala já limpa, tempo é de graça: bastava
/// martelar o botão B entre uma sala e outra pra chegar no andar seguinte com
/// a vida cheia, e poção, coração e escudo passivo perdiam a razão de existir.
///
/// Sala nova é um recurso que o jogador NÃO fabrica parado — o andar tem um
/// número fixo delas, e voltar pra uma já andada não conta (ver
/// `Player.cargasDeSala`). Curar passa a custar exploração de verdade.
class SegundoFolego extends ItemEfeito {
  const SegundoFolego();

  /// Cargas por cura. Com uma carga por sala inédita, sai perto de uma cura a
  /// cada três salas novas.
  static const int custoCargas = 3;

  @override
  bool get usaCargasDeSala => true;

  @override
  String get id => 'segundoFolego';
  @override
  String get spritePath => 'items/segundoFolego.png';
  @override
  Color get cor1 => Palette.jade;
  @override
  Color get cor2 => Palette.vermelho;
  @override
  String nome(BuildContext context) => context.l10n.item_segundoFolego;
  @override
  String descricao(BuildContext context) =>
      context.l10n.item_segundoFolegoDesc;

  @override
  void aoUsarAbility2(Player player) {
    if (player.cargasDeSala < custoCargas) return;

    // Confere a cura ANTES de cobrar: com a vida cheia o `heal` devolve false,
    // e gastar as cargas aí seria queimar exploração por nada.
    if (!player.heal(1)) return;

    player.gastarCargasDeSala(custoCargas);
  }
}

class PassivasAposentadoria {
  static const Map<String, ItemEfeito> porCriatura = {
    'roedor_fogo': RastroFlamejante(),
    'tartaruga_planta': CascoReflexivo(),
    'sapo_agua': BolhaAutonoma(),
    'ave_eletrica': CorrenteReflexa(),
    'tornado_fogo': TornadoResidual(),
    'bomba_fogo': BombaNaEsquiva(),
    'cobra_agua': SaltoAquatico(),
    'urso_planta': BradoReflexo(),
    'grilo_eletrico': ReflexoEletrico(),
    'roda_fogo': ImpetoArdente(),
    'slime_planta': PeconhaReflexiva(),
    'ourico_eletrico': RetaliacaoEletrica(),
    'pinguim_agua': RastroCongelante(),
  };

  static ItemEfeito? de(String creatureId) => porCriatura[creatureId];
}

/// Coletável do pedestal que entrega um [ItemEfeito]. Não pega duas vezes o
/// mesmo item: um segundo `Revezamento` na lista dispararia o gancho duas
/// vezes por troca, dobrando o bônus sem o balanceamento ter dito isso.
class ItemEfeitoPickup extends Collectible {
  final ItemEfeito item;

  ItemEfeitoPickup({required super.position, required this.item})
    : super(
        spritePath: item.spritePath,
        cor1: item.cor1,
        cor2: item.cor2,
      );

  @override
  String? nomeExibido(BuildContext context) => item.nome(context);

  @override
  bool onCollect(Player player) {
    if (player.itens.any((i) => i.id == item.id)) return false;
    player.itens.add(item);
    player.parent?.add(
      TextEffect(
        // Descrição, não nome: o nome já está escrito acima do sprite no chão
        // (ver `Collectible.nomeExibido`), então repeti-lo na coleta não
        // informa nada. O que o jogador ainda não sabe é o que o item FAZ.
        text: item.descricao(player.game.buildContext!),
        position: player.position.clone() + Vector2(0, -player.size.y / 2 - 4),
        color: Palette.amarelo,
      ),
    );
    return true;
  }
}
