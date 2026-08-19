import 'dart:ui' as ui;

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class CreatureSelectOverlay extends StatelessWidget {
  final CreaturesRogueGame game;
  const CreatureSelectOverlay({super.key, required this.game});

  static String _typeLabel(CreatureType tipo) {
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

  static Color _typeColor(CreatureType tipo) {
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                'ESCOLHA SUA CRIATURA',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(8),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: CreatureRegistry.all
                    .map((creature) => _CreatureCard(
                          creature: creature,
                          onTap: () => game.startRun(creature),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatureCard extends StatelessWidget {
  final CreatureData creature;
  final VoidCallback onTap;

  const _CreatureCard({required this.creature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = CreatureSelectOverlay._typeColor(creature.tipo);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Palette.cinza,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<ui.Image>(
              future: PaletteSwapper.createSwappedImage(
                imagePath: creature.spritePath, 
                lightGrayReplacement: creature.corClara, 
                darkGrayReplacement: creature.corEscura, 
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    ),
                  );
                }
            
                if (snapshot.hasData) {
                  return RawImage(
                    image: snapshot.data,
                    width: 48,
                    height: 48,
                    filterQuality: FilterQuality.none, 
                    fit: BoxFit.fill,
                  );
                }
                return const SizedBox(
                  width: 48, 
                  height: 48, 
                  child: Icon(Icons.broken_image, color: Colors.red),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              creature.nome,
              style: const TextStyle(color: Palette.preto, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              CreatureSelectOverlay._typeLabel(creature.tipo),
              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'HP ${creature.stats.maxHp}   VEL ${creature.stats.speed.toInt()}\n'
              'DEF ${creature.stats.defesa.toInt()}   ATK ${creature.stats.ataque.toInt()}',
              style: const TextStyle(color: Palette.preto, fontSize: 12),
            ),
            const Spacer(),
            Text(
              'A: ${creature.ability1.nome}',
              style: const TextStyle(color: Palette.preto, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'B: ${creature.ability2.nome}',
              style: const TextStyle(color: Palette.preto, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
