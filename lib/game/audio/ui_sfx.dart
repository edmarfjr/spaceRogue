import 'package:flutter/foundation.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';

/// Envolve o `onPressed`/`onTap` de um botão de menu/overlay pra tocar
/// `btn.wav` antes de executar a ação de verdade — um ponto só, em vez de
/// repetir `GameAudio.instance.play(Sfx.btn)` em cada botão das telas.
///
/// Passa `null` adiante sem embrulhar: é assim que um botão desabilitado
/// (`onPressed: condicao ? null : acao`) continua desabilitado, sem tocar som
/// nenhum quando o toque não faz nada.
VoidCallback? withBtnSfx(VoidCallback? action) {
  if (action == null) return null;
  return () {
    GameAudio.instance.play(Sfx.btn);
    action();
  };
}
