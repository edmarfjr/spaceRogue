import 'package:flame_audio/flame_audio.dart';

import 'sfx.dart';

/// Efeitos sonoros do jogo — dash, retorno de criatura, dano e ataques
/// elementais (ver [Sfx]). Ponto único de leitura de `assets/sounds/sfx/`.
///
/// Três decisões carregam o peso da parte "performático" do pedido:
///
/// 1. `PlayerMode.lowLatency` em vez do padrão do `AudioPool`
///    (`PlayerMode.mediaPlayer`, elemento `<audio>` do HTML no web). O modo
///    padrão tem overhead real por chamada — em combate, com vários sons
///    disparando no mesmo frame (AoE acertando vários inimigos, rajada de
///    projéteis do mesmo elemento), esse overhead empilha e o som passa a
///    tocar atrasado ("travando"). `lowLatency` usa Web Audio API no web
///    (e o equivalente nativo mais leve nas outras plataformas) — é
///    literalmente pra isso que existe, ver doc de `AudioPool` no pacote
///    `audioplayers`: "extremely quick firing, repetitive, or simultaneous
///    sounds".
/// 2. Vozes fixas por som ([_voicesPerSfx]), criadas uma vez em [preload] e
///    nunca mais — sem usar `AudioPool` (aquele cria player novo sem limite
///    quando fica sem um disponível em `lowLatency`, porque nesse modo ele
///    não escuta o fim da reprodução pra devolver o player ao pool; usar o
///    pool nesse modo vazaria um `AudioPlayer` por toque). Aqui o `play()`
///    sempre reaproveita em turno (round-robin): a voz mais antiga é cortada
///    e reiniciada, nunca cria player novo.
/// 3. Throttle por som ([_throttleMs]). Mesmo com vozes baratas, disparar
///    dezenas por segundo é ruído, não efeito — o piso corta isso.
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

  static const int _voicesPerSfx = 4;
  static const int _throttleMs = 60;

  bool _ready = false;
  bool get isReady => _ready;

  final Map<Sfx, List<AudioPlayer>> _voices = {};
  final Map<Sfx, int> _nextVoice = {};
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
      // Aquece o cache de bytes uma vez: sem isso, cada uma das
      // `_voicesPerSfx` chamadas de `setSource` abaixo buscaria o mesmo
      // arquivo de novo.
      await FlameAudio.audioCache.loadAll(_paths.values.toList());

      for (final entry in _paths.entries) {
        final players = <AudioPlayer>[];
        for (var i = 0; i < _voicesPerSfx; i++) {
          final player = AudioPlayer(playerId: '${entry.key.name}_$i')
            ..audioCache = FlameAudio.audioCache;
          await player.setPlayerMode(PlayerMode.lowLatency);
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(AssetSource(entry.value));
          players.add(player);
        }
        _voices[entry.key] = players;
        _nextVoice[entry.key] = 0;
      }
      _ready = true;
    } catch (_) {
      // Sem áudio, não sem jogo.
    }
  }

  /// Toca [sfx] se as vozes já estiverem prontas, habilitado, e fora do
  /// throttle. Nunca lança e nunca bloqueia o frame — chamável direto de
  /// qualquer `update`/`onCollision` sem `await`.
  void play(Sfx sfx, {double? volume}) {
    if (!_ready || !enabled) return;
    final players = _voices[sfx];
    if (players == null || players.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedAtMs[sfx] ?? 0;
    if (nowMs - last < _throttleMs) return;
    _lastPlayedAtMs[sfx] = nowMs;

    final i = _nextVoice[sfx]!;
    _nextVoice[sfx] = (i + 1) % players.length;

    final player = players[i];
    // Reinicia do zero em vez de tocar de onde parou — é assim que uma
    // "voz" reaproveitada soa como um novo disparo, não como a anterior
    // pulando pra frente.
    player.setVolume(volume ?? this.volume);
    player.seek(Duration.zero);
    player.resume();
  }
}
