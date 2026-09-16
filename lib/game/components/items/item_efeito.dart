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
abstract class ItemEfeito {
  const ItemEfeito();

  /// Chave estável do save. NUNCA renomear depois de publicado.
  String get id;

  String get spritePath;
  Color get cor1;
  Color get cor2;
  String nome(BuildContext context);
  String descricao(BuildContext context);

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
  String get spritePath => 'items/casco.png';
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
  static const double coefDano = 0.8;

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
          speed: 70,
          lifeTime: 1.2,
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

  static const double coefDano = 0.6;
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

    player.parent?.add(
      Projectile(
        owner: player,
        position: player.position.clone(),
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
  bool onCollect(Player player) {
    if (player.itens.any((i) => i.id == item.id)) return false;
    player.itens.add(item);
    player.parent?.add(
      TextEffect(
        text: item.nome(player.game.buildContext!),
        position: player.position.clone() + Vector2(0, -player.size.y / 2 - 4),
        color: Palette.amarelo,
      ),
    );
    return true;
  }
}
