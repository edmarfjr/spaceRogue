import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'sfx.dart';

/// Efeitos sonoros do jogo — dash, retorno de criatura, dano e ataques
/// elementais (ver [Sfx]). Ponto único de leitura de `assets/sounds/sfx/`.
///
/// Decisões que carregam o peso da parte "performático" do pedido:
///
/// 1. `PlayerMode.lowLatency` em vez do padrão do `AudioPool`
///    (`PlayerMode.mediaPlayer`). No Android isso é `SoundPool` — a API do
///    próprio sistema pra "disparo rápido, repetitivo ou simultâneo"; no web,
///    Web Audio API em vez do elemento `<audio>` do HTML.
/// 2. `AudioContextConfig(focus: mixWithOthers)` em CADA voz, setado antes de
///    tocar. Sem isso (regressão real, pegou num teste em campo: som
///    engasgando em combate até o app travar e fechar) cada `resume()` pede
///    foco de áudio ao sistema, o que dispara `AUDIOFOCUS_LOSS` em toda
///    outra voz ativa — com dezenas de vozes isso é uma tempestade de
///    handlers de foco disparando uns nos outros (O(n²) no número de vozes),
///    e é ela, não o SoundPool, que travava a thread principal por segundos
///    até o Android matar o app por ANR. `mixWithOthers` desliga esse
///    comportamento: cada voz toca sem brigar pelo foco com as outras.
/// 3. Vozes fixas por som ([_voiceCounts]), criadas uma vez em [preload] e
///    nunca mais — sem usar `AudioPool` (aquele cria player novo sem limite
///    quando fica sem um disponível em `lowLatency`, porque nesse modo ele
///    não escuta o fim da reprodução pra devolver o player ao pool; usar o
///    pool nesse modo vazaria um `AudioPlayer` por toque). `play()` sempre
///    reaproveita em turno (round-robin): a voz mais antiga é cortada e
///    reiniciada, nunca cria player novo. A contagem por som é proporcional
///    a quanto ele realmente sobrepõe (hit/elementais pedem mais que um
///    efeito de UI ou de evento único) — cada voz é um `AudioPlayer` nativo
///    vivo o jogo inteiro, então não faz sentido dar 4 pra `stairs`.
/// 4. Throttle por som ([_throttleMs]) mais um piso global
///    ([_globalThrottleMs]): um som sozinho não passa de N vezes por
///    segundo, e a soma de sons diferentes tocando ao mesmo tempo (combate
///    com vários elementos em cena) também não passa de um teto — sem o
///    piso global, sete throttles por-som passando ao mesmo tempo ainda é
///    sete chamadas de canal de plataforma no mesmo frame.
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

  /// Quantas vozes cada som ganha — só os que realmente se sobrepõem em
  /// combate (dano e ataques elementais) precisam de mais de duas. O padrão
  /// pra quem não está aqui é [_defaultVoiceCount].
  static const Map<Sfx, int> _voiceCounts = {
    Sfx.hit: 4,
    Sfx.fogo: 3,
    Sfx.agua: 3,
    Sfx.raio: 3,
    Sfx.veneno: 3,
    Sfx.stairs: 1,
    Sfx.pick: 1,
    Sfx.use: 1,
  };
  static const int _defaultVoiceCount = 2;

  static const int _throttleMs = 60;

  /// Piso entre QUAISQUER dois toques, não importa o som — sem isso, sons
  /// diferentes tocando ao mesmo tempo (cada um dentro do próprio throttle)
  /// ainda somam uma rajada de chamadas de canal de plataforma no mesmo
  /// frame.
  static const int _globalThrottleMs = 30;

  bool _ready = false;
  bool get isReady => _ready;

  final Map<Sfx, List<AudioPlayer>> _voices = {};
  final Map<Sfx, int> _nextVoice = {};
  final Map<Sfx, int> _lastPlayedAtMs = {};
  int _lastPlayedAnyAtMs = 0;

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
      // Aquece o cache de bytes uma vez: sem isso, cada voz chamando
      // `setSource` abaixo buscaria o mesmo arquivo de novo.
      await FlameAudio.audioCache.loadAll(_paths.values.toList());

      // `mixWithOthers`: cada voz toca sem pedir foco de áudio exclusivo —
      // é o que evita a tempestade de AUDIOFOCUS_LOSS entre as próprias
      // vozes do jogo (ver doc da classe). Uma instância só, reaproveitada
      // em todas as vozes.
      final audioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();

      for (final entry in _paths.entries) {
        final voiceCount = _voiceCounts[entry.key] ?? _defaultVoiceCount;
        final players = <AudioPlayer>[];
        for (var i = 0; i < voiceCount; i++) {
          final player = AudioPlayer(playerId: '${entry.key.name}_$i')
            ..audioCache = FlameAudio.audioCache;
          await player.setPlayerMode(PlayerMode.lowLatency);
          await player.setAudioContext(audioContext);
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setVolume(volume);
          await player.setSource(AssetSource(entry.value));
          players.add(player);
        }
        _voices[entry.key] = players;
        _nextVoice[entry.key] = 0;
      }
      _ready = true;
    } catch (e, st) {
      // TODO(diagnóstico): trocado de `catch (_) {}` pra log temporário —
      // o app travando em campo sem nenhuma exceção Dart aparecendo no
      // console sugere que o erro real estava sendo engolido aqui ou no
      // fire-and-forget de `play()`. Reverter pra silencioso assim que o
      // crash em combate estiver resolvido de vez (áudio não deve nunca
      // travar o jogo, mas precisamos ver o erro pra saber o que corrigir).
      debugPrint('GameAudio.preload falhou: $e\n$st');
    }
  }

  /// Toca [sfx] se as vozes já estiverem prontas, habilitado, e fora do
  /// throttle (por som e global). Nunca lança e nunca bloqueia o frame —
  /// chamável direto de qualquer `update`/`onCollision` sem `await`.
  void play(Sfx sfx, {double? volume}) {
    if (!_ready || !enabled) return;
    final players = _voices[sfx];
    if (players == null || players.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastPlayedAnyAtMs < _globalThrottleMs) return;
    final last = _lastPlayedAtMs[sfx] ?? 0;
    if (nowMs - last < _throttleMs) return;
    _lastPlayedAtMs[sfx] = nowMs;
    _lastPlayedAnyAtMs = nowMs;

    final i = _nextVoice[sfx]!;
    _nextVoice[sfx] = (i + 1) % players.length;

    final player = players[i];
    // Reinicia do zero via `stop()` + `resume()`, NUNCA `seek(Duration.zero)`
    // — achado em teste de campo (log real do dispositivo): no Android,
    // `PlayerMode.lowLatency` é `SoundPool`, e o `seekTo(0)` do plugin nem
    // sempre devolve resultado pro canal de plataforma; o `Future` do lado
    // Dart fica pendurado até estourar o timeout interno de 30s do
    // `audioplayers`. Cada toque durante um combate empilhava mais um desses
    // — foi isso, não o SoundPool em si, que travava a thread principal por
    // segundos. `stop()` é síncrono e sempre completa; `resume()` depois,
    // com a voz já parada, cai no caminho do SoundPool que começa a
    // reprodução do zero de novo (`soundPool.play`, não `soundPool.resume`).
    //
    // Volume é fixado uma vez no preload (acima); só manda `setVolume` de
    // novo se ALGUÉM pediu um volume diferente pra este toque específico —
    // no caminho comum isso é uma chamada de canal de plataforma a menos.
    //
    // TODO(diagnóstico): `.catchError` nas chamadas abaixo foi o que expôs
    // o bug do `seek` (ver log). Mantido por enquanto pra pegar qualquer
    // outro caso escondido; reverter pra silencioso quando o áudio em
    // combate ficar estável por um tempo.
    if (volume != null) {
      player.setVolume(volume).catchError(
        (e, st) => debugPrint('GameAudio.play(${sfx.name}) setVolume falhou: $e'),
      );
    }
    _restart(sfx, player);
  }

  Future<void> _restart(Sfx sfx, AudioPlayer player) async {
    try {
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('GameAudio.play(${sfx.name}) falhou: $e');
    }
  }
}
