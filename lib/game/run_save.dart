import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Save do progresso DENTRO da run atual (andar, dungeon, boss revelado,
/// stats e grupo do jogador) — não confundir com `CreatureProgress`
/// (desbloqueios, que sobrevivem à morte). Como em qualquer roguelike, este
/// save morre com o jogador (ver `CreaturesRogueGame._handleGameOver`) ou
/// quando "NOVO JOGO" é escolhido por cima de um save existente.
///
/// Um único carregamento no início do app (`load()`, chamado em `main()`);
/// toda gravação depois substitui o JSON inteiro — o estado da run muda por
/// completo a cada andar, não em partes.
class RunSave {
  RunSave._();
  static final RunSave instance = RunSave._();

  static const _key = 'creatures_rogue.run_save';

  late final SharedPreferences _prefs;
  Map<String, dynamic>? _dados;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    _dados = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    _loaded = true;
  }

  bool get hasSave => _dados != null;

  /// Dados brutos da run salva, só pra `CreaturesRogueGame` reconstruir o
  /// estado ao continuar. `null` quando não há save.
  Map<String, dynamic>? get dados => _dados;

  Future<void> salvar(Map<String, dynamic> dados) async {
    _dados = dados;
    await _prefs.setString(_key, jsonEncode(dados));
  }

  Future<void> apagar() async {
    _dados = null;
    await _prefs.remove(_key);
  }
}
