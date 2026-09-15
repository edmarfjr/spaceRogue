import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'collectible.dart';
import '../player/player.dart';

enum PowerUpType { speedUp, fireRateUp, damageUp, hpUp, shieldUp, critChanceUp, critDamageUp, energyUp, energyRegenUp }

/// Sprite, cor e efeito de cada upgrade. Fica numa extension, e não dentro do
/// [PowerUpItem], porque a loja também vende upgrades e precisa exatamente
/// desses três dados sem instanciar o coletável do pedestal.
extension PowerUpTypeData on PowerUpType {
  String get spritePath => switch (this) {
        PowerUpType.hpUp => 'items/garrafa.png',
        PowerUpType.speedUp => 'items/garrafa.png',
        PowerUpType.damageUp => 'items/garrafa.png',
        PowerUpType.fireRateUp => 'items/garrafa.png',
        PowerUpType.shieldUp => 'items/garrafa.png',
        PowerUpType.critChanceUp => 'items/capsula.png',
        PowerUpType.critDamageUp => 'items/capsula.png',
        PowerUpType.energyUp => 'items/garrafa.png',
        PowerUpType.energyRegenUp => 'items/capsula.png',
      };

  Color get cor1 => switch (this) {
        PowerUpType.hpUp => Palette.vermelho,
        PowerUpType.speedUp => Palette.verde,
        PowerUpType.damageUp => Palette.laranja,
        PowerUpType.fireRateUp => Palette.azul,
        PowerUpType.shieldUp => Palette.indigo,
        PowerUpType.critChanceUp => Palette.laranja,
        PowerUpType.critDamageUp => Palette.vermelho,
        PowerUpType.energyUp => Palette.amarelo,
        PowerUpType.energyRegenUp => Palette.laranja,
      };

  Color get cor2 => switch (this) {
        PowerUpType.hpUp => Palette.roxoEsc,
        PowerUpType.speedUp => Palette.verdeEsc,
        PowerUpType.damageUp => Palette.marromEsc,
        PowerUpType.fireRateUp => Palette.royal,
        PowerUpType.shieldUp => Palette.azulEsc,
        PowerUpType.critChanceUp => Palette.laranja,
        PowerUpType.critDamageUp => Palette.vermelho,
        PowerUpType.energyUp => Palette.laranja,
        PowerUpType.energyRegenUp => Palette.marromEsc,
      };

  /// Texto mostrado acima do jogador ao pegar o upgrade.
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
        player.bonusHpItens += 2;
        player.maxHealth += 2;
        player.currentHealth += 2;
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

  PowerUpItem({required Vector2 position, required PowerUpType tipo})
      : type = tipo,
        super(
          position: position,
          spritePath: tipo.spritePath,
          cor1: tipo.cor1,
          cor2: tipo.cor2,
        );

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
