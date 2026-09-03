import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'collectible.dart';
import '../player/player.dart';

/// Itens de uso único que ocupam os dois slots do inventário.
///
/// Nenhum deles pede mira: os dois polegares já estão ocupados (joystick de um
/// lado, habilidades do outro), então clicar num slot no meio da briga já custa
/// movimento — pedir alvo em cima disso seria injogável.
enum ConsumableType { pocao, escudo, congelar, mapa }

extension ConsumableTypeData on ConsumableType {
  String get spritePath => switch (this) {
        ConsumableType.pocao => 'items/potion.png',
        ConsumableType.escudo => 'items/shell.png',
        ConsumableType.congelar => 'items/gelo.png',
        ConsumableType.mapa => 'items/mapa.png',
      };

  Color get cor1 => switch (this) {
        ConsumableType.pocao => Palette.indigo,
        ConsumableType.escudo => Palette.indigo,
        ConsumableType.congelar => Palette.azul,
        ConsumableType.mapa => Palette.bege,
      };

  Color get cor2 => switch (this) {
        ConsumableType.pocao => Palette.cinzaEsc,
        ConsumableType.escudo => Palette.royal,
        ConsumableType.congelar => Palette.royal,
        ConsumableType.mapa => Palette.marromEsc,
      };

  /// Texto mostrado acima do jogador quando o item faz efeito de verdade
  /// (ver `aplicar` — nunca aparece se o efeito não teve serventia).
  String descricao(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      ConsumableType.pocao => l.effect_maisVida(4),
      ConsumableType.escudo => l.effect_escudoAtivo,
      ConsumableType.congelar => l.effect_inimigosCongelados,
      ConsumableType.mapa => l.effect_mapaRevelado,
    };
  }

  /// Efeito no instante em que o slot é clicado. Cada caso reaproveita um
  /// sistema que já existe no Player — nada de mecânica nova por item.
  ///
  /// Devolve `false` quando o efeito não teria serventia nenhuma (poção com
  /// vida cheia, congelar sem inimigo na sala, mapa dentro de sala trancada, em
  /// que o minimapa fica escondido). Nesse caso o `useSlot` NÃO gasta o item —
  /// senão o jogador veria o item desaparecer sem nada acontecer, o que lê como
  /// bug e não como regra.
  bool aplicar(Player player) {
    GameAudio.instance.play(Sfx.use);

    final bool sucesso;
    switch (this) {
      case ConsumableType.pocao:
        sucesso = player.heal(4);
      case ConsumableType.escudo:
        player.shieldHits = 3;
        player.shieldVisualActive = true;
        sucesso = true;
      case ConsumableType.congelar:
        sucesso = player.congelarInimigos(3.0);
      case ConsumableType.mapa:
        sucesso = player.revelarMapa();
    }

    if (sucesso) {
      final context = player.game.buildContext!;
      player.parent?.add(TextEffect(
        text: descricao(context),
        position: player.position.clone() + Vector2(0, -player.size.y / 2 - 4),
        color: Palette.branco,
      ));
    }

    return sucesso;
  }
}

/// Coletável no chão que, em vez de aplicar o efeito na hora, entra num slot
/// livre do inventário.
class ConsumablePickup extends Collectible {
  final ConsumableType type;

  ConsumablePickup({required super.position, required ConsumableType tipo})
      : type = tipo,
        super(
          spritePath: tipo.spritePath,
          cor1: tipo.cor1,
          cor2: tipo.cor2,
        );

  @override
  bool onCollect(Player player) {
    final entrou = player.addConsumable(type);

    if (!entrou) {
      // Dois slots cheios: o item fica no chão, mesma regra do coração com HP
      // cheio (ver `Collectible.onCollect`). O aviso existe porque, sem ele,
      // passar por cima e nada acontecer parece bug.
      parent?.add(TextEffect(
        text: game.buildContext!.l10n.effect_cheio,
        position: position.clone() + Vector2(0, -10),
        color: Palette.branco,
      ));
    }

    return entrou;
  }
}
