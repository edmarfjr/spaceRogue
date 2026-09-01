import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class HudOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GestureDetector(
          onTap: withBtnSfx(() {
            game.pauseEngine(); // Congela o jogo inteiro!
            game.overlays.add('PauseMenu');
          }),
          child: const _GameboyCapsuleButton(label: 'PAUSE'),
        ),
      ),
    );
  }
}

/// Botão em forma de cápsula, no estilo dos botões START/SELECT do Game Boy
/// original: pílula de plástico escuro com o nome impresso embaixo (sem
/// ícone dentro — igual ao hardware de verdade, que não tem símbolo nenhum
/// no botão em si).
class _GameboyCapsuleButton extends StatelessWidget {
  final String label;
  const _GameboyCapsuleButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 104,
          height: 36,
          decoration: BoxDecoration(
            color: UiTheme.pauseCapsule,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Palette.preto, width: 4),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'pixelFont',
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: Palette.cinzaEsc,
            //shadows: [Shadow(color: Palette.preto, offset: Offset(1, 1))],
          ),
        ),
      ],
    );
  }
}