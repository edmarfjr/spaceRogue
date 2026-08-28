import 'package:flame_audio/flame_audio.dart';

/// Player de música de fundo — estrutura pronta, sem faixa nenhuma tocando
/// ainda (o jogo não tem trilha de fundo por enquanto, só o efeito sonoro do
/// `GameAudio`). Pra ligar uma faixa no futuro: solte o arquivo em
/// `assets/sounds/music/`, declare em `pubspec.yaml` se for arquivo novo, e
/// chame `GameMusic.instance.play('music/nome_do_arquivo.mp3')` (ex.: ao
/// entrar na masmorra, ao trocar de bioma, na luta de boss) — o caminho é
/// relativo a `assets/sounds/` (prefixo acertado em `GameAudio.preload`, que
/// roda antes de qualquer partida começar).
///
/// Separado de `GameAudio` de propósito: música é um único player em loop
/// (`FlameAudio.bgm`), efeito sonoro é pool de vários players tocando ao
/// mesmo tempo — são dois problemas diferentes, não faz sentido no mesmo
/// objeto.
class GameMusic {
  GameMusic._();
  static final GameMusic instance = GameMusic._();

  String? _current;
  double volume = 0.5;
  bool enabled = true;

  /// Troca a faixa atual. Não faz nada se [asset] já é a faixa tocando —
  /// evita reiniciar a música do zero toda vez que o chamador re-emite o
  /// mesmo "entrar na masmorra".
  Future<void> play(String asset) async {
    if (!enabled || _current == asset) return;
    _current = asset;
    try {
      await FlameAudio.bgm.play(asset, volume: volume);
    } catch (_) {
      _current = null;
    }
  }

  Future<void> stop() async {
    _current = null;
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }
}
