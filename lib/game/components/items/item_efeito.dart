import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/efeitos_temporarios.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'dart:math';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
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
/// `defesa`, o stat que fora disso só alimenta o escudo passivo.
class CascaInstavel extends ItemEfeito {
  const CascaInstavel();

  static const double coefDano = 1.5;

  @override
  String get id => 'cascaInstavel';
  @override
  String get spritePath => 'items/cascoQuebrado.png';
  @override
  Color get cor1 => Palette.laranja;
  @override
  Color get cor2 => Palette.verdeEsc;
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
        dmg: player.creatureData.stats.defesa * coefDano,
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

/// Levar dano queima quem estiver perto. Premia jogar no aperto, o oposto do
/// que o resto do kit defensivo pede.
class PeleDeCinzas extends ItemEfeito {
  const PeleDeCinzas();

  static const double alcance = 32.0;
  static const int ticks = 4;

  @override
  String get id => 'peleDeCinzas';
  @override
  String get spritePath => 'items/casco.png';
  @override
  Color get cor1 => Palette.laranja;
  @override
  Color get cor2 => Palette.vermelho;
  @override
  String nome(BuildContext context) => context.l10n.item_peleDeCinzas;
  @override
  String descricao(BuildContext context) => context.l10n.item_peleDeCinzasDesc;

  @override
  void aoTomarDano(Player player, double danoFinal, CreatureType tipoAtacante) {
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
