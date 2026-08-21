import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/game_settings.dart';

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
  Future<void> _escolher(ControlScheme scheme) async {
    widget.game.controlScheme = scheme;
    await GameSettings.instance.setControlScheme(scheme);
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
            const Text(
              'CONFIGURAÇÕES',
              style: TextStyle(color: Palette.preto, fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const Text(
              'CONTROLE',
              style: TextStyle(color: Palette.preto, fontSize: 14, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
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
                      onPressed: scheme == atual ? null : () => _escolher(scheme),
                      child: Text(
                        scheme.rotulo,
                        style: TextStyle(
                          fontSize: 16,
                          color: scheme == atual ? Palette.branco : Palette.preto,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 420,
              child: Text(
                atual.descricao,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.preto, fontSize: 13),
              ),
            ),
            const SizedBox(height: 40),
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
              onPressed: () {
                widget.game.overlays.remove('Settings');
                widget.game.overlays.add('MainMenu');
              },
              child: const Text(' VOLTAR ', style: TextStyle(fontSize: 20, color: Palette.preto)),
            ),
          ],
        ),
      ),
    );
  }
}
