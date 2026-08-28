import 'package:flame_audio/flame_audio.dart';

import 'sfx.dart';

/// Efeitos sonoros do jogo — dash, retorno de criatura, dano e ataques
/// elementais (ver [Sfx]). Ponto único de leitura de `assets/sounds/sfx/`.
///
/// Duas decisões carregam o peso da parte "performático" do pedido:
///
/// 1. Pool de players fixo por som ([_maxPlayersPerSfx]), montado uma vez em
///    [preload]. `play()` nunca cria player novo — reaproveitar é o que evita
///    o gargalo de abrir canal de áudio nativo a cada esquiva/hit/tiro.
/// 2. Throttle por som ([_throttleMs]). Um AoE acertando 10 inimigos ou uma
///    rajada de projéteis do mesmo tipo dispara dezenas de eventos no mesmo
///    frame; sem piso isso vira ruído e desperdiça as chamadas nativas do
///    item 1 à toa.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  static const Map<Sfx, String> _paths = {
    Sfx.dash: 'sfx/dash.wav',
    Sfx.retorno: 'sfx/retorno.wav',
    Sfx.liberar: 'sfx/liberar.wav',
    Sfx.enemy_die: 'sfx/enemy_die.wav',
    Sfx.die: 'sfx/die.wav',
    Sfx.stairs: 'sfx/enterStairs.wav',
    Sfx.btn: 'sfx/btn.wav',
    Sfx.hit: 'sfx/hit.wav',
    Sfx.fogo: 'sfx/fogo.wav',
    Sfx.agua: 'sfx/agua.wav',
    Sfx.raio: 'sfx/raio.wav',
    Sfx.veneno: 'sfx/veneno.wav',
    Sfx.pick: 'sfx/pick.wav',
    Sfx.use: 'sfx/pick.wav',
  };

  static const int _maxPlayersPerSfx = 4;
  static const int _throttleMs = 60;

  bool _ready = false;
  bool get isReady => _ready;

  final Map<Sfx, AudioPool> _pools = {};
  final Map<Sfx, int> _lastPlayedAtMs = {};

  double volume = 0.7;
  bool enabled = true;

  Future<void>? _preloadFuture;

  /// Chamado no boot (`main.dart`, sem `await` — só pra começar cedo) e de
  /// novo no `onLoad` do jogo (`CreaturesRogueGame`, com `await`, mesmo
  /// tratamento de `_preloadCombatSprites`: nenhum som deve faltar no
  /// primeiro uso). "Single-flight": a segunda chamada não recarrega nada,
  /// só espera o mesmo `Future` da primeira — sem isso as duas chamadas
  /// disparariam `loadAll`/`createPool` em paralelo, duplicando trabalho.
  Future<void> preload() => _preloadFuture ??= _doPreload();

  /// Se o áudio do dispositivo falhar (driver ausente, permissão negada,
  /// etc.), o jogo segue mudo em vez de travar: [play] já sai cedo enquanto
  /// `_ready` for false.
  Future<void> _doPreload() async {
    try {
      // `flame_audio` resolve caminho como `<prefix><path>`, e o prefixo
      // padrão é `assets/audio/` — não bate com `assets/sounds/`, que é onde
      // o projeto guarda tudo (sfx e música). Sem isso, `loadAll`/`createPool`
      // buscam um arquivo que não existe; no web isso não falha na hora (o
      // dev server devolve o fallback da SPA em vez de 404), só quebra depois
      // ao tocar, como "Format error" — parecia problema de codec do .wav,
      // mas era o caminho errado o tempo todo. `updatePrefix` acerta tanto o
      // cache de efeitos quanto o de `FlameAudio.bgm` (música) numa chamada só.
      FlameAudio.updatePrefix('assets/sounds/');
      await FlameAudio.audioCache.loadAll(_paths.values.toList());
      for (final entry in _paths.entries) {
        _pools[entry.key] = await FlameAudio.createPool(
          entry.value,
          maxPlayers: _maxPlayersPerSfx,
        );
      }
      _ready = true;
    } catch (_) {
      // Sem áudio, não sem jogo.
    }
  }

  /// Toca [sfx] se o pool já estiver pronto, habilitado, e fora do throttle.
  /// Nunca lança e nunca bloqueia o frame — chamável direto de qualquer
  /// `update`/`onCollision` sem `await`.
  void play(Sfx sfx, {double? volume}) {
    if (!_ready || !enabled) return;
    final pool = _pools[sfx];
    if (pool == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedAtMs[sfx] ?? 0;
    if (nowMs - last < _throttleMs) return;
    _lastPlayedAtMs[sfx] = nowMs;

    pool.start(volume: volume ?? this.volume);
  }
}
