import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/creatures/creature_data.dart';
import 'package:spacerogue/game/components/creatures/creature_registry.dart';
import 'package:spacerogue/game/components/creatures/creature_type.dart';
import 'package:spacerogue/game/space_rogue_game.dart';

class CreatureSelectOverlay extends StatelessWidget {
  final SpacerogueGame game;
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
        return Colors.redAccent;
      case CreatureType.planta:
        return Colors.lightGreen;
      case CreatureType.agua:
        return Colors.lightBlueAccent;
      case CreatureType.eletrico:
        return Colors.yellowAccent;
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
                padding: const EdgeInsets.all(16),
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
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              creature.nome,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              CreatureSelectOverlay._typeLabel(creature.tipo),
              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'HP ${creature.stats.maxHp}   VEL ${creature.stats.speed.toInt()}\n'
              'DEF ${creature.stats.defesa.toInt()}   ATK ${creature.stats.ataque.toInt()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            Text(
              'A: ${creature.ability1.nome}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'B: ${creature.ability2.nome}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
