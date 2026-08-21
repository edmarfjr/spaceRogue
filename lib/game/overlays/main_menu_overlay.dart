import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class MainMenuOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

/// Stateful só por causa do seletor de controle: trocar o esquema já vale no
/// jogo na hora (o setter de `controlScheme` remonta os componentes), mas o
/// menu precisa se redesenhar pra mostrar qual está escolhido.
///
/// A escolha não é gravada em disco — volta pro padrão a cada abertura do app.
/// Persistir fica pra tela de configurações.
class _MainMenuOverlayState extends State<MainMenuOverlay> {
  @override
  Widget build(BuildContext context) {
    final atual = widget.game.controlScheme;

    return Material(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CREATURES ROGUE',
              style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const Text(
              'CONTROLE',
              style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 3),
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
                        backgroundColor: scheme == atual ? Colors.redAccent : Colors.transparent,
                        side: BorderSide(
                          color: scheme == atual ? Colors.redAccent : Colors.white38,
                        ),
                      ),
                      onPressed: scheme == atual
                          ? null
                          : () => setState(() => widget.game.controlScheme = scheme),
                      child: Text(
                        scheme.rotulo,
                        style: TextStyle(
                          fontSize: 16,
                          color: scheme == atual ? Colors.white : Colors.white70,
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
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                // Leva pro seletor de criaturas. A run só começa de fato
                // (e o motor só despausa) quando uma criatura é escolhida.
                widget.game.overlays.remove('MainMenu');
                widget.game.overlays.add('CreatureSelect');
              },
              child: const Text('JOGAR', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
