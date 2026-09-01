import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/game_music.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

/// Preferências do jogador que valem entre sessões — esquema de controle,
/// idioma e volume, escolhidos na tela de configurações.
///
/// Mesmo formato de [CreatureProgress]: um único `load()` no início do app
/// (chamado em `main()`), e cada mudança depois grava direto no
/// SharedPreferences.
class GameSettings {
  GameSettings._();
  static final GameSettings instance = GameSettings._();

  static const _controlSchemeKey = 'creatures_rogue.control_scheme';
  static const _localeKey = 'creatures_rogue.locale';
  static const _soundEnabledKey = 'creatures_rogue.sound_enabled';
  static const _musicEnabledKey = 'creatures_rogue.music_enabled';

  static const ControlScheme defaultControlScheme = ControlScheme.botoes;

  late final SharedPreferences _prefs;
  ControlScheme _controlScheme = defaultControlScheme;
  bool _loaded = false;

  /// `null` = segue o idioma do sistema (padrão). Vive num `ValueNotifier`,
  /// não num campo simples como `_controlScheme`, porque trocar o idioma
  /// precisa reconstruir o `MaterialApp` na hora — é o único jeito de mudar
  /// `Locale` depois do app já ter subido (ver `main.dart`).
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    _controlScheme = _parseControlScheme(_prefs.getString(_controlSchemeKey));
    localeNotifier.value = _parseLocale(_prefs.getString(_localeKey));
    // Aplica direto nos players (ver `GameAudio`/`GameMusic`), sem esperar a
    // tela de configurações abrir — preferência lida uma vez aqui, igual
    // `controlScheme`.
    GameAudio.instance.enabled = _prefs.getBool(_soundEnabledKey) ?? true;
    GameMusic.instance.enabled = _prefs.getBool(_musicEnabledKey) ?? true;
    _loaded = true;
  }

  ControlScheme get controlScheme => _controlScheme;

  Future<void> setControlScheme(ControlScheme scheme) async {
    _controlScheme = scheme;
    // Grava o `name`, não o `index`: se um esquema novo entrar no meio do enum,
    // um índice salvo passaria a apontar pro esquema errado.
    await _prefs.setString(_controlSchemeKey, scheme.name);
  }

  Locale? get locale => localeNotifier.value;

  Future<void> setLocale(Locale? locale) async {
    localeNotifier.value = locale;
    if (locale == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, locale.languageCode);
    }
  }

  static Locale? _parseLocale(String? salvo) => salvo == null ? null : Locale(salvo);

  bool get soundEnabled => GameAudio.instance.enabled;

  Future<void> setSoundEnabled(bool value) async {
    GameAudio.instance.enabled = value;
    await _prefs.setBool(_soundEnabledKey, value);
  }

  bool get musicEnabled => GameMusic.instance.enabled;

  /// Além de marcar a flag (que trava `GameMusic.play` de novas faixas),
  /// pausa/retoma a faixa atual — sem isso desligar música no meio de uma
  /// trilha já tocando não silenciava nada até a próxima troca de faixa.
  Future<void> setMusicEnabled(bool value) async {
    GameMusic.instance.enabled = value;
    if (value) {
      await GameMusic.instance.resume();
    } else {
      await GameMusic.instance.pause();
    }
    await _prefs.setBool(_musicEnabledKey, value);
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
