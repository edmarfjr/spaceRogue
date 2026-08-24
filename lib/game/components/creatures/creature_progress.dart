import 'package:shared_preferences/shared_preferences.dart';

/// Progresso de desbloqueio das criaturas: quais estão liberadas pra jogar, e
/// quantas mortes já foram acumuladas de cada uma (contagem que mais pra
/// frente aciona o boss de cada criatura — ver brainstorm de desbloqueio).
///
/// Um único carregamento no início do app (`load()`, chamado em `main()`);
/// toda mudança depois grava direto no SharedPreferences.
class CreatureProgress {
  CreatureProgress._();
  static final CreatureProgress instance = CreatureProgress._();

  static const _unlockedKey = 'creatures_rogue.unlocked_ids';
  static const _killCountPrefix = 'creatures_rogue.kills.';

  /// Quem começa liberado antes de qualquer partida: uma criatura de tipo
  /// diferente cada, pra primeira escolha ser escolha de verdade e não só
  /// "a única opção".
  static const List<String> defaultUnlocked = [
    'roedor_fogo',
    'ave_eletrica',
    'tartaruga_planta',
    'sapo_agua',
    'ourico_eletrico',
    'caranguejo_fogo'
  ];

  late final SharedPreferences _prefs;
  Set<String> _unlockedIds = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    _unlockedIds = (_prefs.getStringList(_unlockedKey) ?? defaultUnlocked).toSet();
    _loaded = true;
  }

  bool isUnlocked(String creatureId) => _unlockedIds.contains(creatureId);

  Future<void> unlock(String creatureId) async {
    if (_unlockedIds.add(creatureId)) {
      await _prefs.setStringList(_unlockedKey, _unlockedIds.toList());
    }
  }

  int killCount(String creatureId) => _prefs.getInt('$_killCountPrefix$creatureId') ?? 0;

  /// Chamado quando um inimigo dessa criatura morre. Retorna a contagem nova
  /// (ainda sem gatilho de boss — isso entra quando o sistema de boss existir).
  Future<int> incrementKill(String creatureId) async {
    final novo = killCount(creatureId) + 1;
    await _prefs.setInt('$_killCountPrefix$creatureId', novo);
    return novo;
  }
}
