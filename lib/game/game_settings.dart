import 'package:shared_preferences/shared_preferences.dart';

import 'package:creatures_rogue/game/creatures_rogue_game.dart';

/// Preferências do jogador que valem entre sessões — hoje só o esquema de
/// controle, escolhido na tela de configurações.
///
/// Mesmo formato de [CreatureProgress]: um único `load()` no início do app
/// (chamado em `main()`), e cada mudança depois grava direto no
/// SharedPreferences.
class GameSettings {
  GameSettings._();
  static final GameSettings instance = GameSettings._();

  static const _controlSchemeKey = 'creatures_rogue.control_scheme';

  static const ControlScheme defaultControlScheme = ControlScheme.botoes;

  late final SharedPreferences _prefs;
  ControlScheme _controlScheme = defaultControlScheme;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    _controlScheme = _parseControlScheme(_prefs.getString(_controlSchemeKey));
    _loaded = true;
  }

  ControlScheme get controlScheme => _controlScheme;

  Future<void> setControlScheme(ControlScheme scheme) async {
    _controlScheme = scheme;
    // Grava o `name`, não o `index`: se um esquema novo entrar no meio do enum,
    // um índice salvo passaria a apontar pro esquema errado.
    await _prefs.setString(_controlSchemeKey, scheme.name);
  }

  /// Volta ao padrão em vez de estourar quando o valor gravado não corresponde
  /// a nenhum esquema atual (pref de uma versão antiga, ou lixo).
  static ControlScheme _parseControlScheme(String? salvo) {
    for (final scheme in ControlScheme.values) {
      if (scheme.name == salvo) return scheme;
    }
    return defaultControlScheme;
  }
}
