import 'package:shared_preferences/shared_preferences.dart';

import 'package:creatures_rogue/game/game_settings.dart';

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
  static const _introKey = 'creatures_rogue.intro_concluida';

  /// Ninguém começa liberado: a primeira criatura vem da escolha no fim da
  /// intro (ver `IntroOverlay`), e é a única jogável na primeira run. A lista
  /// com 10 ids que morava aqui era atalho de teste.
  static const List<String> defaultUnlocked = [];

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

  /// Esta criatura está liberada pra jogar?
  ///
  /// O GOD MODE libera TODAS. É cheat de teste, igual às outras duas metades
  /// dele (`Player.takeDamage` ignora dano, `Enemy.takeDamage` mata de um
  /// golpe): sem isto, testar uma criatura específica exigia derrotar o boss
  /// dela antes, e as de andar alto eram praticamente inalcançáveis.
  ///
  /// Mente na LEITURA, nunca na escrita: [_unlockedIds] continua intacto, e
  /// desligar o god mode devolve a lista real de quem o jogador de fato
  /// desbloqueou.
  ///
  /// Aqui, e não na tela de seleção, porque este é o funil por onde as três
  /// leituras passam — a lista, o cadeado de cada linha e a silhueta do VS.
  /// Espalhar a condição pelos três era garantir que um deles fosse esquecido.
  bool isUnlocked(String creatureId) =>
      GameSettings.instance.godMode || _unlockedIds.contains(creatureId);

  /// A intro (diálogo + escolha da criatura inicial) já foi concluída alguma
  /// vez. Enquanto for falso, "NOVO JOGO" leva pra intro em vez do seletor.
  bool get introConcluida => _prefs.getBool(_introKey) ?? false;

  /// Fecha a intro liberando a criatura escolhida. Uma chamada só de
  /// propósito: se a flag e o unlock fossem gravados em momentos diferentes,
  /// o app morto no meio deixaria zero criatura liberada E nenhuma intro pra
  /// liberar uma — e o seletor abriria com uma criatura travada selecionada.
  Future<void> concluirIntro(String starterId) async {
    _unlockedIds.add(starterId);
    await _prefs.setStringList(_unlockedKey, _unlockedIds.toList());
    await _prefs.setBool(_introKey, true);
  }

  /// Desfaz a intro e os desbloqueios (as contagens de morte por criatura
  /// continuam). Existe pra dar pra ver a intro de novo sem reinstalar o app
  /// — sem isso ela aparece uma vez na vida do aparelho.
  Future<void> resetIntro() async {
    _unlockedIds = defaultUnlocked.toSet();
    await _prefs.setStringList(_unlockedKey, _unlockedIds.toList());
    await _prefs.setBool(_introKey, false);
  }

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
