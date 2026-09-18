import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Sprite dos dois estados (neutro, pressionado) do botão de cada
/// [AbilityTipo] — `ui/btn<Tipo>.png`, tira 48x24, 2 quadros de 24x24.
/// Cinza claro/escuro do desenho vira `UiTheme.actionButtonCor1`/`Cor2` via
/// `PaletteSwapper`, mesmo tratamento dos sprites de criatura.
///
/// Carregado uma vez só, mesma razão do `AbilityIcons`: o `AbilityButton`
/// nasce no `onLoad` do jogo, antes de existir jogador — e o tipo muda
/// conforme a criatura da run.
class AbilityButtonSprites {
  static const Map<AbilityTipo, String> _caminhos = {
    AbilityTipo.ataque: 'ui/btnAtaque.png',
    AbilityTipo.defesa: 'ui/btnDefesa.png',
    AbilityTipo.esquiva: 'ui/btnEsquiva.png',
  };

  /// Botão de TROCA de criatura: não é habilidade, então fica fora do mapa
  /// por [AbilityTipo]. Mesmo formato de tira (48x24, dois quadros de 24x24)
  /// e mesmo tratamento de paleta.
  static const String _caminhoTroca = 'ui/btnTroca.png';
  static late final List<Sprite> _quadrosTroca;

  static final Map<AbilityTipo, List<Sprite>> _quadros = {};

  /// Chamada uma vez no `onLoad` do jogo, antes de montar os controles.
  static Future<void> carregar() async {
    for (final entrada in _caminhos.entries) {
      final ui.Image imagem = await PaletteSwapper.createSwappedImage(
        imagePath: entrada.value,
        lightGrayReplacement: UiTheme.actionButtonCor1,
        darkGrayReplacement: UiTheme.actionButtonCor2,
      );
      _quadros[entrada.key] = List.generate(
        2,
        (i) => Sprite(
          imagem,
          srcPosition: Vector2(i * imagem.height.toDouble(), 0),
          srcSize: Vector2(imagem.height.toDouble(), imagem.height.toDouble()),
        ),
      );
    }

    final ui.Image troca = await PaletteSwapper.createSwappedImage(
      imagePath: _caminhoTroca,
      lightGrayReplacement: UiTheme.actionButtonCor1,
      darkGrayReplacement: UiTheme.actionButtonCor2,
    );
    _quadrosTroca = List.generate(
      2,
      (i) => Sprite(
        troca,
        srcPosition: Vector2(i *troca.height.toDouble(), 0),
        srcSize: Vector2(troca.height.toDouble(), troca.height.toDouble()),
      ),
    );
  }

  static Sprite neutro(AbilityTipo tipo) => _quadros[tipo]![0];
  static Sprite pressionado(AbilityTipo tipo) => _quadros[tipo]![1];

  static Sprite get trocaNeutro => _quadrosTroca[0];
  static Sprite get trocaPressionado => _quadrosTroca[1];
}
