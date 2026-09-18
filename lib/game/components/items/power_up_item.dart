import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'collectible.dart';
import 'item_descritor.dart';
import '../player/player.dart';

/// Upgrade permanente de stat.
///
/// Sprite e cores são campos do próprio valor do enum, não `switch`: criar um
/// upgrade novo é acrescentar UMA linha na lista abaixo mais um `case` em
/// [descricao] e outro em [aplicar]. Antes eram cinco `switch` separados pra
/// manter em sincronia, e esquecer um passava batido no compilador.
///
/// Corpo dentro do enum, e não numa extension: método de extension NÃO conta
/// pra satisfazer [ItemDescritor].
enum PowerUpType implements ItemDescritor {
  speedUp('items/speedUp.png', Palette.verde, Palette.verdeEsc),
  fireRateUp('items/firerateUp.png', Palette.vermelho, Palette.royal),
  damageUp('items/dmgUp.png', Palette.vermelho, Palette.marromEsc),
  hpUp('items/hpUp.png', Palette.vermelho, Palette.roxoEsc),
  shieldUp('items/escudoUp.png', Palette.indigo, Palette.azulEsc),
  critChanceUp('items/critChance.png', Palette.vermelho, Palette.laranja),
  critDamageUp('items/critDmg.png', Palette.vermelho, Palette.laranja),
  energyUp('items/energyUp.png', Palette.laranja, Palette.marromEsc),
  energyRegenUp('items/energyRegen.png', Palette.laranja, Palette.marromEsc);

  const PowerUpType(this.spritePath, this.cor1, this.cor2);

  @override
  final String spritePath;
  @override
  final Color cor1;
  @override
  final Color cor2;

  @override
  String get id => name;

  /// Upgrade de stat não tem nome separado do efeito: "+DANO" já É o nome.
  /// Alias em vez de um texto novo, de propósito — o rótulo no chão continua
  /// exatamente o que era antes desta interface existir.
  @override
  String nome(BuildContext context) => descricao(context);

  /// Texto mostrado acima do jogador ao pegar o upgrade.
  @override
  String descricao(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      PowerUpType.speedUp => l.effect_maisVelocidade,
      PowerUpType.fireRateUp => l.effect_maisVelAtaque,
      PowerUpType.damageUp => l.effect_maisDano,
      PowerUpType.hpUp => l.effect_maisVidaMaxima,
      PowerUpType.shieldUp => l.effect_maisEscudoMaximo,
      PowerUpType.critChanceUp => l.effect_maisChanceCrit,
      PowerUpType.critDamageUp => l.effect_maisDanoCrit,
      PowerUpType.energyUp => l.effect_maisEnergia,
      PowerUpType.energyRegenUp => l.effect_maisRegenEnergia,
    };
  }

  /// Multiplicadores, não soma direta nos stats: `BaseStats` é `const` e
  /// compartilhado por todas as instâncias da criatura (ver Player.velMult).
  void aplicar(Player player) {
    switch (this) {
      case PowerUpType.speedUp:
        player.velMult += 0.10;
      case PowerUpType.fireRateUp:
        // Multiplica em vez de subtrair: dois upgrades nunca podem levar o
        // cooldown a zero (ou negativo, que travaria o indicador da Hud).
        player.cdMult *= 0.88;
      case PowerUpType.damageUp:
        Player.danoMult += 0.15;
      case PowerUpType.hpUp:
        // O bônus vai pro campo que sobrevive à troca E pro total de agora:
        // `trocarCriatura` recompõe `maxHealth` como `stats.maxHp + bônus`.
        player.bonusHpItens += 1;
        player.maxHealth += 1;
        player.currentHealth += 1;
      case PowerUpType.shieldUp:
        player.bonusShieldItens += 1;
        player.shieldMax += 1;
        player.shield += 1;
      case PowerUpType.critChanceUp:
        player.critChance += 2.5;
      case PowerUpType.energyUp:
        // Soma o ganho também na energia ATUAL, igual ao `hpUp`: um teto maior
        // que não enche na hora lê como se o item não tivesse feito nada.
        final ganho = player.energiaMax * 0.20;
        player.energiaMax += ganho;
        player.energia += ganho;
      case PowerUpType.energyRegenUp:
        player.energiaRegen *= 1.25;
      case PowerUpType.critDamageUp:
        player.critMult += 0.50;
    }
  }
}

/// Upgrade permanente da run, pego no pedestal da sala de tesouro.
///
/// Cada tipo tem sprite e cor próprios: com todos usando `heart.png` não havia
/// como saber o que se estava pegando.
class PowerUpItem extends Collectible {
  final PowerUpType type;

  PowerUpItem({required super.position, required PowerUpType tipo})
      : type = tipo,
        super(
          spritePath: tipo.spritePath,
          cor1: tipo.cor1,
          cor2: tipo.cor2,
        );

  @override
  String? nomeExibido(BuildContext context) => type.descricao(context);

  @override
  bool onCollect(Player player) {
    type.aplicar(player);
    player.parent?.add(TextEffect(
      text: type.descricao(player.game.buildContext!),
      position: player.position.clone() + Vector2(0, -player.size.y / 2 - 4),
      color: Palette.amarelo,
    ));
    return true; // upgrade sempre pode ser pego
  }
}
