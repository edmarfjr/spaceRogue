import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';

/// Ícones das habilidades, um por [AbilityTipo], carregados uma vez só.
///
/// Existe porque os botões são montados no `onLoad` do jogo, antes de haver
/// jogador — então eles não podem carregar "o sprite da habilidade 1", que só
/// se sabe quando a run começa. Com os três já em memória, botão e indicador
/// escolhem o ícone na hora de desenhar, e trocar de criatura entre runs não
/// custa carregamento nenhum.
class AbilityIcons {
  /// O mapa mora aqui, e não como getter no [AbilityTipo], pra manter o enum
  /// livre de conhecimento sobre assets.
  static const Map<AbilityTipo, String> _caminhos = {
    AbilityTipo.ataque: 'ui/ataque.png',
    AbilityTipo.defesa: 'ui/defesa.png',
    AbilityTipo.esquiva: 'ui/esquiva.png',
  };

  static const Map<AbilityTipo, String> _caminhosP = {
    AbilityTipo.ataque: 'ui/ataqueP.png',
    AbilityTipo.defesa: 'ui/defesaP.png',
    AbilityTipo.esquiva: 'ui/esquivaP.png',
  };

  static final Map<AbilityTipo, Sprite> _sprites = {};
  static final Map<AbilityTipo, Sprite> _spritesP = {};

  /// Chamada uma vez no `onLoad` do jogo, antes de montar os controles.
  static Future<void> carregar() async {
    for (final entrada in _caminhos.entries) {
      _sprites[entrada.key] = await Sprite.load(entrada.value);
    }
    for (final entrada in _caminhosP.entries) {
      _spritesP[entrada.key] = await Sprite.load(entrada.value);
    }
  }

  static Sprite of(AbilityTipo tipo) => _sprites[tipo]!;
  static Sprite ofP(AbilityTipo tipo) => _spritesP[tipo]!;
}
