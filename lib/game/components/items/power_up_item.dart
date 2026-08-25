import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'collectible.dart';
import '../player/player.dart';

enum PowerUpType { speedUp, fireRateUp, damageUp, hpUp, shieldUp }

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
      };

  Color get cor1 => switch (this) {
        PowerUpType.hpUp => Palette.vermelho,
        PowerUpType.speedUp => Palette.verde,
        PowerUpType.damageUp => Palette.laranja,
        PowerUpType.fireRateUp => Palette.azul,
        PowerUpType.shieldUp => Palette.indigo,
      };

  Color get cor2 => switch (this) {
        PowerUpType.hpUp => Palette.roxoEsc,
        PowerUpType.speedUp => Palette.verdeEsc,
        PowerUpType.damageUp => Palette.marromEsc,
        PowerUpType.fireRateUp => Palette.royal,
        PowerUpType.shieldUp => Palette.azulEsc,
      };

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
        player.maxHealth += 2;
        player.currentHealth += 2;
      case PowerUpType.shieldUp:
        player.shieldMax += 1;
        player.shield += 1;
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
    return true; // upgrade sempre pode ser pego
  }
}
