import 'dart:ui' as ui;

import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Imagem (já com a paleta trocada — `UiTheme.pauseCapsuleCor1`/`Cor2`) do
/// botão de pausa: `ui/btnPause.png`, tira 64x32, 2 quadros de 32x32 (neutro,
/// pressionado). Carregada uma vez só no `onLoad` do jogo — o botão é um
/// widget do Flutter fora da árvore do Flame (`HudOverlay`), então não pode
/// usar `Sprite`/`onLoad` de componente como o resto da UI; guardamos a
/// `ui.Image` crua e o `_PauseButton` mesmo recorta o quadro certo
/// (`Canvas.drawImageRect`) na hora de desenhar.
class PauseButtonSprite {
  static ui.Image? _imagem;

  static ui.Image get imagem => _imagem!;

  static Future<void> carregar() async {
    _imagem = await PaletteSwapper.createSwappedImage(
      imagePath: 'ui/btnPause.png',
      lightGrayReplacement: UiTheme.pauseCapsuleCor1,
      darkGrayReplacement: UiTheme.pauseCapsuleCor2,
    );
  }
}
