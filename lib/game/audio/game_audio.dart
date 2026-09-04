import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'sfx.dart';

/// Efeitos sonoros do jogo — dash, retorno de criatura, dano e ataques
/// elementais (ver [Sfx]). Ponto único de leitura de `assets/sounds/sfx/`.
///
/// Decisões que carregam o peso da parte "performático" do pedido — cada uma
/// veio de um teste real em campo (log de dispositivo Android), não de
/// suposição:
///
/// 1. `PlayerMode.mediaPlayer`, NÃO `lowLatency`. No Android, `lowLatency` é
///    `SoundPool`: cada `play()` faz o sistema alocar um `AudioTrack` nativo
///    de verdade (visto se repetindo no log, `createTrack_l`, durante o
///    próprio combate) — com um pool fixo de vozes reaproveitadas isso soma
///    trabalho nativo real por toque, saturando a MESMA thread de
///    plataforma que processa outras coisas (confirmado desligando o áudio:
///    a vibração, que usa essa thread, ficou instantânea). `SoundPool`
///    existe pra "várias vozes tocando ao mesmo tempo sem gerência manual"
///    — MAS este arquivo já faz a própria gerência de vozes (item 3), então
///    a vantagem do SoundPool não vale nada aqui, só o custo. `MediaPlayer`
///    aloca o `AudioTrack` uma vez por player e reaproveita — o preço fica
///    só no preload, não a cada toque.
/// 2. `player.seek(Duration.zero)` antes de `player.resume()` pra reiniciar
///    uma voz — e SÓ nesse modo. No `SoundPool` o `seekTo(0)` do plugin não
///    completa de forma confiável (achado real: `Future` pendurado até
///    estourar os 30s de timeout do `audioplayers`, um por toque, empilhando
///    até travar o app). No `MediaPlayer`, `seekTo` é implementação de
///    verdade, com callback de conclusão — o padrão que quebrava num modo é
///    o correto no outro. NUNCA chamar `stop()` aqui: no `MediaPlayer` isso
///    força o estado "Stopped", que exige `prepare()` de novo antes do
///    próximo `start()` — o oposto do que uma voz reaproveitável precisa.
/// 3. `AudioContextConfig(focus: mixWithOthers)` em CADA voz, setado antes de
///    tocar. Sem isso cada `resume()` pede foco de áudio ao sistema, o que
///    dispara `AUDIOFOCUS_LOSS` em toda outra voz ativa — com dezenas de
///    vozes isso é uma tempestade de handlers de foco disparando uns nos
///    outros (O(n²) no número de vozes), travando a thread principal até o
///    Android matar o app por ANR. `mixWithOthers` desliga isso.
/// 4. Vozes fixas por som ([_voiceCounts]), criadas uma vez em [preload] e
///    nunca mais. `play()` sempre reaproveita em turno (round-robin): a voz
///    mais antiga é cortada e reiniciada, nunca cria player novo. A
///    contagem por som é proporcional a quanto ele realmente sobrepõe
///    (hit/elementais pedem mais que um efeito de UI ou de evento único).
/// 5. Throttle por som ([_throttleMs]) mais um piso global
///    ([_globalThrottleMs]): mesmo com trabalho nativo mais barato por
///    trigger (item 1), ainda existe um teto de quantas chamadas de canal de
///    plataforma por segundo fazem sentido — sem o piso global, sons
///    diferentes tocando juntos ainda somam uma rajada no mesmo frame.
/// 6. Guarda de voz ocupada ([_busy]): uma voz só aceita um
///    `seek()`+`resume()` em voo por vez. Se o rodízio cai numa voz ainda em
///    voo, o toque é DESCARTADO (não enfileira, não tenta outra voz) — o
///    teto de chamadas simultâneas em voo passa a ser o número de vozes, não
///    a taxa de disparo do combate.
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
    Sfx.defesa: 'sfx/defesa.wav',
    Sfx.tiro: 'sfx/tiro.wav',
    Sfx.estouro: 'sfx/shot.wav',
  };

  /// Quantas vozes cada som ganha — só os que realmente se sobrepõem em
  /// combate (dano e ataques elementais) precisam de mais de duas. O padrão
  /// pra quem não está aqui é [_defaultVoiceCount].
  static const Map<Sfx, int> _voiceCounts = {
    Sfx.hit: 10,
    Sfx.fogo: 5,
    Sfx.agua: 5,
    Sfx.raio: 8,
    Sfx.veneno: 5,
    Sfx.stairs: 1,
    Sfx.pick: 1,
    Sfx.use: 1,
  };
  static const int _defaultVoiceCount = 2;

  static const int _throttleMs = 60;

  /// Piso entre QUAISQUER dois toques, não importa o som — sem isso, sons
  /// diferentes tocando ao mesmo tempo (cada um dentro do próprio throttle)
  /// ainda somam uma rajada de chamadas de canal de plataforma no mesmo
  /// frame. Era 120ms enquanto o modo era `lowLatency`/`SoundPool` (cada
  /// `play()` alocava `AudioTrack` nativo de verdade); depois da troca pra
  /// `PlayerMode.mediaPlayer` (item 1 da doc da classe) esse custo por toque
  /// já não existe mais — 80ms (~12 toques/s) volta a dar folga sem reabrir
  /// a saturação antiga.
  static const int _globalThrottleMs = 80;

  bool _ready = false;
  bool get isReady => _ready;

  final Map<Sfx, List<AudioPlayer>> _voices = {};
  final Map<Sfx, int> _nextVoice = {};
  final Map<Sfx, int> _lastPlayedAtMs = {};
  int _lastPlayedAnyAtMs = 0;

  /// Vozes com um `stop()`/`resume()` em voo agora — achado de campo #2
  /// (depois do `seek` travado): nada limitava quantos `_restart` ficavam
  /// pendurados ao mesmo tempo. Em combate pesado, disparo mais rápido que o
  /// canal de plataforma consegue confirmar vira fila crescente — os sons
  /// não tocam na hora, tocam depois, todos de uma vez, quando o combate já
  /// acabou. Esta guarda faz o teto real ser o número de vozes (35), não a
  /// taxa de disparo: se a voz escolhida no rodízio já está ocupada, ESTE
  /// toque é descartado (não tenta outra voz, não enfileira) — perder um som
  /// isolado em pico de combate é aceitável, acumular um estoque de sons
  /// atrasados não é.
  final Set<AudioPlayer> _busy = {};
  int _droppedByBusy = 0;

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
          await player.setPlayerMode(PlayerMode.mediaPlayer);
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
    // Sempre avança o rodízio, mesmo se esta voz estiver ocupada e o toque
    // for descartado — é isso que faz a PRÓXIMA chamada cair numa voz
    // diferente em vez de tentar a mesma de novo.
    _nextVoice[sfx] = (i + 1) % players.length;

    final player = players[i];
    if (_busy.contains(player)) {
      // TODO(diagnóstico): contador temporário — preciso saber se a guarda
      // de vozes ocupadas está de fato descartando toques em combate, ou se
      // (com o throttle atual) uma voz nunca chega a estar ocupada de novo
      // antes do próximo toque, o que provaria que o atraso não é fila do
      // lado Dart. Reverter junto com o resto do diagnóstico.
      _droppedByBusy++;
      debugPrint('GameAudio: descartou ${sfx.name} (voz ocupada), total=$_droppedByBusy');
      return;
    }
    _busy.add(player);

    // Volume é fixado uma vez no preload (acima); só manda `setVolume` de
    // novo se ALGUÉM pediu um volume diferente pra este toque específico —
    // no caminho comum isso é uma chamada de canal de plataforma a menos.
    if (volume != null) {
      player.setVolume(volume).catchError(
        (e, st) => debugPrint('GameAudio.play(${sfx.name}) setVolume falhou: $e'),
      );
    }
    _restart(sfx, player);
  }

  /// `seek(0)` DE VERDADE espera a posição mudar antes de tocar — no
  /// `PlayerMode.mediaPlayer` isso é seguro (callback de conclusão real, ver
  /// doc da classe), diferente do `lowLatency`/`SoundPool` onde o mesmo
  /// `await` pendurava 30s. Por isso vale esperar ELE — é o que evita duas
  /// chamadas de `seek` correndo ao mesmo tempo na mesma voz.
  ///
  /// `resume()` já dispara solto, sem esperar: uma vez que a posição voltou
  /// pro zero, começar a tocar não tem corrida nenhuma pra evitar, e segurar
  /// a voz "ocupada" até o `resume()` também confirmar só encurtava a folga
  /// pra dois sons do mesmo tipo tocarem quase juntos (achado de campo: a
  /// guarda descartava som demais em rajada, ex. dois ataques de água quase
  /// simultâneos). Liberar a voz assim que o `seek` aterrissa é suficiente.
  ///
  /// TODO(diagnóstico): `catch`/log foi o que expôs o bug do `seek` no modo
  /// antigo (ver histórico do arquivo). Mantido por enquanto pra pegar
  /// qualquer outro caso escondido; reverter pra silencioso quando o áudio
  /// em combate ficar estável por um tempo.
  Future<void> _restart(Sfx sfx, AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
    } catch (e) {
      debugPrint('GameAudio.play(${sfx.name}) seek falhou: $e');
      _busy.remove(player);
      return;
    }
    _busy.remove(player);
    player.resume().catchError(
      (e, st) => debugPrint('GameAudio.play(${sfx.name}) resume falhou: $e'),
    );
  }
}
