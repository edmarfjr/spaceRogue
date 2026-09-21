import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/l10n/creature_i18n.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import '../audio/ui_sfx.dart';

/// Tela de vitória — passou do andar final da última dungeon (ver
/// `CreaturesRogueGame.ehUltimaDungeon`). Mostra o elenco que chegou lá e o
/// tempo, com as duas saídas possíveis: menu principal ou jogo novo.
///
/// Os dois botões espelham os da `GameOverMenu` de propósito, inclusive o
/// motivo de o de menu NÃO chamar `resetGame`: iniciar uma run só pra
/// esconder outra atrás do menu deixava dois `Player` vivos ao mesmo tempo. A
/// run terminada fica parada e pausada até o jogador escolher de novo.
class VictoryOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  static const double _ladoSprite = 32;

  /// Sprites recolorados das criaturas da run, por id. Carregados uma vez —
  /// `PaletteSwapper` é assíncrono, então não dá pra fazer isso no `build`.
  final Map<String, ui.Image> _sprites = {};

  @override
  void initState() {
    super.initState();
    _carregarSprites();
  }

  Future<void> _carregarSprites() async {
    for (final id in widget.game.criaturasUsadas) {
      final criatura = CreatureRegistry.all.firstWhere(
        (c) => c.id == id,
        // Id salvo de uma versão em que a criatura existia e hoje não mais:
        // cai na primeira do registro em vez de estourar a tela de vitória.
        orElse: () => CreatureRegistry.all.first,
      );
      final img = await PaletteSwapper.createSwappedImage(
        imagePath: criatura.spritePath,
        lightGrayReplacement: criatura.corClara,
        darkGrayReplacement: criatura.corEscura,
      );
      if (!mounted) return;
      setState(() => _sprites[id] = img);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Material(
      color: Palette.preto.withAlpha(220),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Palette.branco,
              border: Border.all(color: Palette.preto, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.victory_titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Palette.preto,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.victory_tempo(game.tempoDeRunFormatado),
                  style: const TextStyle(color: Palette.preto, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.victory_elenco,
                  style: const TextStyle(
                    color: Palette.preto,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                // `Wrap`: o elenco pode passar de três (criatura que morreu ou
                // se aposentou continua na lista), então não cabe numa linha
                // fixa.
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final id in game.criaturasUsadas)
                      SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: _ladoSprite,
                              height: _ladoSprite,
                              child: _sprites[id] == null
                                  ? null
                                  : RawImage(
                                      image: _sprites[id],
                                      // `contain` porque forma base é 16x16 e
                                      // evoluída 24x24 — sem isso cada uma
                                      // apareceria no tamanho nativo.
                                      width: _ladoSprite,
                                      height: _ladoSprite,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.none,
                                    ),
                            ),
                            Text(
                              creatureName(context, id),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Palette.preto,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _Botao(
                  texto: context.l10n.gameOver_restart,
                  fonte: 20,
                  onPressed: () {
                    game.overlays.remove('Victory');
                    game.resetGame();
                  },
                ),
                const SizedBox(height: 12),
                _Botao(
                  texto: context.l10n.gameOver_menuPrincipal,
                  fonte: 16,
                  onPressed: () {
                    game.overlays.remove('Victory');
                    game.overlays.add('MainMenu');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Botao extends StatelessWidget {
  final String texto;
  final double fonte;
  final VoidCallback onPressed;

  const _Botao({
    required this.texto,
    required this.fonte,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.branco,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Palette.preto, width: 2),
        ),
      ),
      onPressed: withBtnSfx(onPressed),
      child: Text(
        texto,
        style: TextStyle(fontSize: fonte, color: Palette.preto),
      ),
    );
  }
}
