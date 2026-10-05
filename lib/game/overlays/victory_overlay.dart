import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/overlays/resumo_run.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import '../audio/ui_sfx.dart';

/// Tela de vitória — passou do andar final da última dungeon (ver
/// `CreaturesRogueGame.ehUltimaDungeon`). Mostra o resumo da run (ver
/// [ResumoRun]), com as duas saídas possíveis: menu principal ou jogo novo.
///
/// Os dois botões espelham os da `GameOverMenu` de propósito, inclusive o
/// motivo de o de menu NÃO chamar `resetGame`: iniciar uma run só pra
/// esconder outra atrás do menu deixava dois `Player` vivos ao mesmo tempo. A
/// run terminada fica parada e pausada até o jogador escolher de novo.
class VictoryOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.preto.withAlpha(220),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: UiTheme.backgroundMenuCor,
              border: const BordaDupla(cor: Palette.preto, espessura: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.victory_titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: UiTheme.txtCor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Sem `FittedBox` aqui (a vitória rola em vez de encolher), então
                // a largura desconta margem e padding do cartão pra caber num
                // celular em retrato.
                ResumoRun(
                  game: game,
                  largura: (MediaQuery.sizeOf(context).width - 80).clamp(
                    200.0,
                    320.0,
                  ),
                ),
                const SizedBox(height: 20),
                _Botao(
                  texto: context.l10n.gameOver_restart,
                  fonte: 20,
                  onPressed: () {
                    game.overlays.remove('Victory');
                    game.resetGame();
                  },
                ),
                const SizedBox(height: 12),
                _Botao(
                  texto: context.l10n.gameOver_menuPrincipal,
                  fonte: 16,
                  onPressed: () {
                    game.overlays.remove('Victory');
                    game.overlays.add('MainMenu');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Botao extends StatelessWidget {
  final String texto;
  final double fonte;
  final VoidCallback onPressed;

  const _Botao({
    required this.texto,
    required this.fonte,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: UiTheme.btnCor,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        elevation: 0,
        shape: const BordaDuplaShape(),
      ),
      onPressed: withBtnSfx(onPressed),
      child: Text(
        texto,
        style: TextStyle(fontSize: fonte, color: UiTheme.txtCor),
      ),
    );
  }
}
