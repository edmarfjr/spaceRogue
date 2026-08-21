import 'dart:ui' as ui;

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class CreatureSelectOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const CreatureSelectOverlay({super.key, required this.game});

  static String typeLabel(CreatureType tipo) {
    switch (tipo) {
      case CreatureType.fogo:
        return 'Fogo';
      case CreatureType.planta:
        return 'Planta';
      case CreatureType.agua:
        return 'Água';
      case CreatureType.eletrico:
        return 'Elétrico';
      case CreatureType.neutro:
        return 'Neutro';
    }
  }

  static Color typeColor(CreatureType tipo) {
    switch (tipo) {
      case CreatureType.fogo:
        return Palette.vermelho;
      case CreatureType.planta:
        return Palette.verde;
      case CreatureType.agua:
        return Palette.azul;
      case CreatureType.eletrico:
        return Palette.amarelo;
      case CreatureType.neutro:
        return Colors.grey;
    }
  }

  @override
  State<CreatureSelectOverlay> createState() => _CreatureSelectOverlayState();
}

class _CreatureSelectOverlayState extends State<CreatureSelectOverlay> {
  // Nunca abre já selecionando uma criatura travada, mesmo que a ordem de
  // CreatureRegistry.all mude no futuro.
  late CreatureData _selected = CreatureRegistry.all.firstWhere(
    (c) => CreatureProgress.instance.isUnlocked(c.id),
    orElse: () => CreatureRegistry.all.first,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.branco,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                'ESCOLHA SUA CRIATURA',
                style: TextStyle(color: Palette.preto, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 160,
                      child: _CreatureList(
                        selected: _selected,
                        onSelect: (creature) => setState(() => _selected = creature),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CreatureDetailPanel(
                        creature: _selected,
                        onPlay: () => widget.game.startRun(_selected),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coluna da esquerda: uma linha por criatura, travada ou não conforme
/// [CreatureProgress].
class _CreatureList extends StatelessWidget {
  final CreatureData selected;
  final ValueChanged<CreatureData> onSelect;

  const _CreatureList({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.branco,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.all(6),
      child: ListView.separated(
        itemCount: CreatureRegistry.all.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final creature = CreatureRegistry.all[index];
          final isSelected = creature.id == selected.id;
          final locked = !CreatureProgress.instance.isUnlocked(creature.id);

          return _CreatureListTile(
            creature: creature,
            isSelected: isSelected,
            locked: locked,
            onTap: locked ? null : () => onSelect(creature),
          );
        },
      ),
    );
  }
}

class _CreatureListTile extends StatelessWidget {
  final CreatureData creature;
  final bool isSelected;
  final bool locked;
  final VoidCallback? onTap;

  const _CreatureListTile({
    required this.creature,
    required this.isSelected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CreatureSelectOverlay.typeColor(creature.tipo);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        //decoration: BoxDecoration(
        //  color: isSelected ? accent.withAlpha(60) : Colors.transparent,
        //  borderRadius: BorderRadius.circular(8),
        //  border: Border(left: BorderSide(color: locked ? Colors.white24 : accent, width: 4)),
        //),
        child: Row(
          children: [
            Expanded(
              child: Text(
                locked ? '???' : creature.nome,
                style: TextStyle(
                  color: locked ? Palette.indigo : Palette.preto,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (locked) const Icon(Icons.lock, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Painel da direita: sprite + nome/tipo em cima, status ao lado das
/// habilidades embaixo — layout tirado direto do rascunho.
class _CreatureDetailPanel extends StatelessWidget {
  final CreatureData creature;
  final VoidCallback onPlay;

  const _CreatureDetailPanel({required this.creature, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Palette.branco,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: Palette.preto, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20),
                    _CreatureSprite(creature: creature, size: 80),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0),
                              border: Border(
                                right: BorderSide(color: Palette.preto, width: 2),
                                bottom: BorderSide(color: Palette.preto, width: 2),
                              ),
                            ),
                            child: Text(
                              '${creature.nome} \n Tipo: ${CreatureSelectOverlay.typeLabel(creature.tipo)} ',
                              style: const TextStyle(color: Palette.preto, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Palette.preto, width: 2),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatLine('SAÚDE', creature.stats.maxHp.toString()),
                              _StatLine('VELOCIDADE', creature.stats.speed.toInt().toString()),
                              _StatLine('ATAQUE', creature.stats.ataque.toInt().toString()),
                              _StatLine('DEFESA', creature.stats.defesa.toInt().toString()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(0),
                                border: Border(
                                  right: BorderSide(color: Palette.preto, width: 2),
                                  bottom: BorderSide(color: Palette.preto, width: 2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Habilidades:',
                                    style: const TextStyle(color: Palette.preto, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    creature.ability1.nome,
                                    style: const TextStyle(color: Palette.preto, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    creature.ability2.nome,
                                    style: const TextStyle(color: Palette.preto, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPlay,
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.branco,
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Palette.preto, width: 2),
              ),
            ),
            child: const Text('JOGAR', style: TextStyle(color: Palette.preto, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
                  ),
      ],
    );
  }
}

/// Rótulo à esquerda, número à direita, numa linha só.
///
/// O rascunho empilha o número embaixo do rótulo, mas em landscape de celular
/// (~360dp de altura) 4 stats de 2 linhas somam ~160px numa faixa que tem
/// ~100px — era exatamente o "BOTTOM OVERFLOWED". Uma linha por stat cabe em
/// qualquer altura e mantém o número destacado.
class _StatLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Palette.preto, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: Palette.preto, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Sprite da criatura já com a paleta trocada — as mesmas cores que ela tem
/// em jogo. `Image.asset` não serve aqui: o PNG em disco é cinza-marcador
/// (169/84), quem pinta é o [PaletteSwapper], que devolve `ui.Image`, não um
/// asset — daí o FutureBuilder + RawImage.
class _CreatureSprite extends StatelessWidget {
  final CreatureData creature;
  final double size;

  const _CreatureSprite({required this.creature, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<ui.Image>(
        // Cache por caminho+cores dentro do PaletteSwapper: mesma textura que
        // o jogo usa, sem reprocessar a cada rebuild.
        future: PaletteSwapper.createSwappedImage(
          imagePath: creature.spritePath,
          lightGrayReplacement: creature.corClara,
          darkGrayReplacement: creature.corEscura,
        ),
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45));
          }
          return RawImage(
            image: image,
            width: size,
            height: size,
            // OBRIGATÓRIO: sem `fit`, o paintImage do Flutter assume
            // BoxFit.scaleDown, que só REDUZ. Um sprite de 16x16 já cabe em
            // qualquer caixa maior, então ele ficava desenhado em 16x16 no
            // canto — a caixa crescia com `size`, a imagem não.
            fit: BoxFit.contain,
            // Sem isso o upscale de 16x16 sai borrado.
            filterQuality: FilterQuality.none,
          );
        },
      ),
    );
  }
}
