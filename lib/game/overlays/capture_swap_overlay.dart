import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/l10n/ability_passive_i18n.dart';
import 'package:creatures_rogue/l10n/creature_i18n.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
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
              Text(
                context.l10n.captureSwap_titulo,
                style: const TextStyle(color: Palette.preto, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.captureSwap_instrucao,
                style: const TextStyle(color: Palette.cinzaEsc, fontSize: 12),
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
                      rotulo: context.l10n.captureSwap_novaCaptura,
                      destaque: true,
                      onSoltar: () => game.resolverTrocaCaptura(null),
                    ),
                    for (int i = 0; i < game.companionCreatures.length; i++) ...[
                      const SizedBox(width: 10),
                      if (game.companionCreatures[i] != null)
                        _TrocaCard(
                          creature: game.companionCreatures[i]!,
                          rotulo: context.l10n.captureSwap_slot(i + 1),
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
            creatureName(context, creature.id),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Palette.preto, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.captureSwap_habilidade(abilityName(context, creature.ability1)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Palette.preto, fontSize: 9),
          ),
          Text(
            context.l10n.captureSwap_passiva(passiveName(context, creature.passive)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Palette.preto, fontSize: 9),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: withBtnSfx(onSoltar),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.branco,
                padding: const EdgeInsets.symmetric(vertical: 6),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Palette.preto, width: 2),
                ),
              ),
              child: Text(
                context.l10n.captureSwap_soltar,
                style: const TextStyle(color: Palette.preto, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
