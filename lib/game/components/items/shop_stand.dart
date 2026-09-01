import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'collectible.dart';
import '../player/player.dart';

/// Um balcão da loja: o sprite do que está à venda, com o preço escrito
/// embaixo. Encostar compra.
///
/// O que ele vende vem no callback [entregar], em vez de um enum próprio —
/// assim a loja monta um balcão de consumível, de upgrade ou de cura com a
/// mesma classe, sem duplicar a lógica de cobrança. O callback devolve `false`
/// quando a entrega não deu (inventário cheio, por exemplo), e nesse caso a
/// moeda NÃO é cobrada.
class ShopStand extends Collectible {
  final int preco;
  final bool Function(Player player) entregar;

  /// Aviso quando [entregar] recusa. Varia por balcão: "CHEIO" só faz sentido
  /// pro inventário, e leria errado numa cura recusada por vida cheia. `null`
  /// usa o aviso padrão — resolvido só na hora do uso, via `game.buildContext`,
  /// porque o default de um parâmetro precisa ser constante e `AppLocalizations`
  /// exige `BuildContext`.
  final String? msgFalha;

  ShopStand({
    required super.position,
    required this.preco,
    required this.entregar,
    required super.spritePath,
    this.msgFalha,
    super.cor1,
    super.cor2,
  });

  static final TextPaint _precoPaint = TextPaint(
    style: const TextStyle(
      fontFamily: 'pixelFont',
      color: Palette.amarelo,
      fontSize: 6,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Palette.preto, offset: Offset(1, 1)),
        Shadow(color: Palette.preto, offset: Offset(-1, -1)),
        Shadow(color: Palette.preto, offset: Offset(1, -1)),
        Shadow(color: Palette.preto, offset: Offset(-1, 1)),
      ],
    ),
  );

  @override
  bool onCollect(Player player) {
    final l = game.buildContext!.l10n;

    if (player.coins < preco) {
      _avisar(l.effect_semMoeda);
      return false; // continua no balcão: dá pra voltar com dinheiro
    }

    if (!entregar(player)) {
      _avisar(msgFalha ?? l.effect_cheio);
      return false;
    }

    player.coins -= preco;
    return true;
  }

  void _avisar(String texto) {
    parent?.add(TextEffect(
      text: texto,
      position: position.clone() + Vector2(0, -12),
      color: Palette.branco,
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _precoPaint.render(
      canvas,
      '$preco',
      Vector2(size.x / 2, size.y + 1),
      anchor: Anchor.topCenter,
    );
  }
}
