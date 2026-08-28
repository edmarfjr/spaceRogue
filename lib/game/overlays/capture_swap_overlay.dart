import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'creature_select_overlay.dart' show CreatureSprite;

/// Tela de troca quando uma captura fecha a volta com o grupo já cheio
/// (PIVOT_TREINADOR.md §4.3, pedido do usuário: decisão na hora, mesmo em
/// combate — `CreaturesRogueGame.capturarCriatura` já pausou o motor antes
/// de abrir isto). Quatro cards: a criatura recém-capturada mais os três
/// integrantes atuais. Tocar em "SOLTAR" num card resolve a troca —
/// soltar a recém-capturada mantém o grupo como estava, soltar um atual
/// põe a nova no lugar dele. A solta some de vez, sem reserva.
class CaptureSwapOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const CaptureSwapOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final nova = game.capturaPendente;
    // Só deveria acontecer entre o overlay ser removido e o frame seguinte
    // reconstruir a árvore — nada pra mostrar, não desenha nada.
    if (nova == null) return const SizedBox.shrink();

    return Material(
      color: Palette.preto.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Palette.branco,
            border: Border.all(color: Palette.preto, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GRUPO CHEIO — QUEM FICA?',
                style: TextStyle(color: Palette.preto, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toque em SOLTAR no card que deve sair do grupo.',
                style: TextStyle(color: Palette.cinzaEsc, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TrocaCard(
                      creature: nova,
                      rotulo: 'NOVA CAPTURA',
                      destaque: true,
                      onSoltar: () => game.resolverTrocaCaptura(null),
                    ),
                    for (int i = 0; i < game.companionCreatures.length; i++) ...[
                      const SizedBox(width: 10),
                      if (game.companionCreatures[i] != null)
                        _TrocaCard(
                          creature: game.companionCreatures[i]!,
                          rotulo: 'SLOT ${i + 1}',
                          destaque: false,
                          onSoltar: () => game.resolverTrocaCaptura(i),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrocaCard extends StatelessWidget {
  final CreatureData creature;
  final String rotulo;
  final bool destaque;
  final VoidCallback onSoltar;

  const _TrocaCard({
    required this.creature,
    required this.rotulo,
    required this.destaque,
    required this.onSoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: destaque ? Palette.bege : Palette.branco,
        border: Border.all(color: Palette.preto, width: destaque ? 3 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            rotulo,
            style: const TextStyle(color: Palette.preto, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          CreatureSprite(creature: creature, size: 48),
          const SizedBox(height: 4),
          Text(
            creature.nome,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Palette.preto, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Hab: ${creature.ability1.nome}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Palette.preto, fontSize: 9),
          ),
          Text(
            'Pass: ${creature.passive.nome}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Palette.preto, fontSize: 9),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSoltar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.branco,
                padding: const EdgeInsets.symmetric(vertical: 6),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Palette.preto, width: 2),
                ),
              ),
              child: const Text(
                'SOLTAR',
                style: TextStyle(color: Palette.preto, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
