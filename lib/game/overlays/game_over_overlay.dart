import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/overlays/resumo_run.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

class GameOverMenu extends StatelessWidget {
  final CreaturesRogueGame game;
  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final estreita = Responsive.ehEstreita(context);

    return ResponsiveOverlayScaffold(
      background: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: UiTheme.backgroundMenuCor,
          border: const BordaDupla(cor: Palette.preto, espessura: 4),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.gameOver_titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: UiTheme.txtCor,
                fontSize: estreita ? 34 : 50,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ResumoRun(game: game, largura: 320),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: UiTheme.btnCor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: const BordaDuplaShape(),
              ),
              onPressed: withBtnSfx(() {
                game.overlays.remove('GameOver');
                // `resetGame` (→ `startRun`) é quem decide se a Hud entra
                // agora ou depois: numa run nova ele abre o `BossReveal`
                // primeiro, com o motor PAUSADO, e deixa a Hud e o
                // `resumeEngine` pro `dismissBossReveal`.
                //
                // Antes daqui saíam um `overlays.add('Hud')` e um
                // `resumeEngine()` fixos, que atropelavam essa decisão: o
                // botão de pausa aparecia funcional em cima da tela de VS, e
                // o jogo já rodava atrás dela.
                game.resetGame();
              }),
              child: Text(
                context.l10n.gameOver_restart,
                style: const TextStyle(fontSize: 20, color: UiTheme.txtCor),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: UiTheme.btnCor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: const BordaDuplaShape(),
              ),
              onPressed: withBtnSfx(() {
                game.overlays.remove('GameOver');
                // Sem resetGame() aqui: chamar startRun (via resetGame) só pra
                // esconder a run atrás do menu criava dois "startRun" em
                // sequência com o motor pausado, e o Player/Companion da run
                // morta sobrevivia junto com o novo (ver PIVOT_TREINADOR.md).
                // O CreatureSelectOverlay já chama startRun quando o jogador
                // de fato escolhe jogar de novo — essa run parada e pausada
                // fica só esperando, sem custo de gameplay nenhum.
                game.overlays.add('MainMenu'); // Volta pro Menu Principal
                // O motor já foi pausado na morte, então continua pausado
              }),
              child: Text(
                context.l10n.gameOver_menuPrincipal,
                style: const TextStyle(fontSize: 16, color: UiTheme.txtCor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
