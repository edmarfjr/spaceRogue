import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/game_settings.dart';
import 'package:creatures_rogue/l10n/gen/app_localizations.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

class SettingsOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

/// Stateful por causa do seletor de controle: trocar o esquema já vale no jogo
/// na hora (o setter de `controlScheme` remonta os componentes), mas a tela
/// precisa se redesenhar pra mostrar qual está escolhido.
///
/// A escolha é gravada em disco por [GameSettings], então sobrevive ao
/// fechamento do app.
class _SettingsOverlayState extends State<SettingsOverlay> {
  bool _resetado = false;

  Future<void> _resetar() async {
    await CreatureProgress.instance.resetIntro();
    if (mounted) setState(() => _resetado = true);
  }

  Future<void> _escolher(ControlScheme scheme) async {
    widget.game.controlScheme = scheme;
    await GameSettings.instance.setControlScheme(scheme);
    if (mounted) setState(() {});
  }

  // Sem `setState` aqui: `GameSettings.setLocale` já muda `localeNotifier`,
  // que reconstrói o `MaterialApp` inteiro (ver `main.dart`) — esta tela é
  // descendente dele, então reconstrói sozinha já com o idioma novo.
  void _escolherIdioma(Locale? locale) {
    GameSettings.instance.setLocale(locale);
  }

  Future<void> _alternarSom(bool valor) async {
    await GameSettings.instance.setSoundEnabled(valor);
    if (mounted) setState(() {});
  }

  Future<void> _alternarMusica(bool valor) async {
    await GameSettings.instance.setMusicEnabled(valor);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final atual = widget.game.controlScheme;

    return Material(
      color: Palette.branco,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.settings_titulo,
              style: const TextStyle(color: Palette.preto, fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.settings_controle,
              style: const TextStyle(color: Palette.preto, fontSize: 14, letterSpacing: 3),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final scheme in ControlScheme.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        //elevation: 0,
                        backgroundColor: scheme == atual ? Palette.preto : Palette.branco,
                        side: BorderSide(
                          color: Palette.preto
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Palette.preto, width: 5),
                        ),
                      ),
                      onPressed: withBtnSfx(scheme == atual ? null : () => _escolher(scheme)),
                      child: Text(
                        scheme.rotulo(context),
                        style: TextStyle(
                          fontSize: 16,
                          color: scheme == atual ? Palette.branco : Palette.preto,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 420,
              child: Text(
                atual.descricao(context),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.preto, fontSize: 13),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.settings_idioma,
              style: const TextStyle(color: Palette.preto, fontSize: 14, letterSpacing: 3),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final MapEntry(key: locale, value: rotulo) in {
                  null: context.l10n.settings_idiomaSistema,
                  for (final loc in AppLocalizations.supportedLocales) loc: loc.languageCode.toUpperCase(),
                }.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        backgroundColor: locale == GameSettings.instance.locale ? Palette.preto : Palette.branco,
                        side: BorderSide(color: Palette.preto),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Palette.preto, width: 5),
                        ),
                      ),
                      onPressed: withBtnSfx(
                        locale == GameSettings.instance.locale ? null : () => _escolherIdioma(locale),
                      ),
                      child: Text(
                        rotulo,
                        style: TextStyle(
                          fontSize: 16,
                          color: locale == GameSettings.instance.locale ? Palette.branco : Palette.preto,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.settings_audio,
              style: const TextStyle(color: Palette.preto, fontSize: 14, letterSpacing: 3),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.settings_som, style: const TextStyle(color: Palette.preto, fontSize: 14)),
                Switch(
                  value: GameSettings.instance.soundEnabled,
                  activeThumbColor: Palette.preto,
                  onChanged: (valor) => _alternarSom(valor),
                ),
                const SizedBox(width: 10),
                Text(context.l10n.settings_musica, style: const TextStyle(color: Palette.preto, fontSize: 14)),
                Switch(
                  value: GameSettings.instance.musicEnabled,
                  activeThumbColor: Palette.preto,
                  onChanged: (valor) => _alternarMusica(valor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Apaga a flag de intro e as criaturas liberadas. Sem isto a
            // intro aparece uma vez na vida do aparelho, e não dá pra
            // revê-la sem reinstalar o app.
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.branco,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Palette.preto, width: 2),
                ),
              ),
              onPressed: withBtnSfx(_resetado ? null : _resetar),
              child: Text(
                _resetado ? context.l10n.settings_progressoResetado : context.l10n.settings_resetarProgresso,
                style: const TextStyle(fontSize: 14, color: Palette.preto),
              ),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.branco,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Palette.preto, width: 2),
                ),
              ),
              onPressed: withBtnSfx(() {
                widget.game.overlays.remove('Settings');
                widget.game.overlays.add(widget.game.settingsReturnOverlay);
              }),
              child: Text(context.l10n.settings_voltar, style: const TextStyle(fontSize: 20, color: Palette.preto)),
            ),
          ],
        ),
      ),
    );
  }
}
