import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';

/// Sprite dos dois estados (neutro, pressionado) do botão de cada
/// [AbilityTipo] — `ui/btn<Tipo>.png`, tira 48x24, 2 quadros de 24x24.
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

  static final Map<AbilityTipo, List<Sprite>> _quadros = {};

  /// Chamada uma vez no `onLoad` do jogo, antes de montar os controles.
  static Future<void> carregar() async {
    for (final entrada in _caminhos.entries) {
      final ui.Image imagem = await Flame.images.load(entrada.value);
      _quadros[entrada.key] = List.generate(
        2,
        (i) => Sprite(
          imagem,
          srcPosition: Vector2(i * 24.0, 0),
          srcSize: Vector2(24, 24),
        ),
      );
    }
  }

  static Sprite neutro(AbilityTipo tipo) => _quadros[tipo]![0];
  static Sprite pressionado(AbilityTipo tipo) => _quadros[tipo]![1];
}
