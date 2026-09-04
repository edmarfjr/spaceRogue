import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';

enum DotKind { veneno, queimadura }

class Dot {
  final DotKind kind;

  /// Tipo elemental do dano do tick. Guardado cru de propósito: quem
  /// multiplica é o `takeDamage` do alvo, uma vez só. Pré-escalar aqui
  /// aplicaria a vantagem duas vezes.
  final CreatureType tipo;

  final double dano;
  final double intervalo;
  final Color cor;
  final int tetoTicks;

  /// Se true, reaplicar soma ticks (desgaste). Se false, reaplicar só devolve
  /// a contagem cheia (estouro).
  final bool acumula;

  int ticks;
  double timer;

  Dot._({
    required this.kind,
    required this.tipo,
    required this.dano,
    required this.intervalo,
    required this.cor,
    required this.tetoTicks,
    required this.acumula,
    required this.ticks,
  }) : timer = intervalo;

  factory Dot.criar(DotKind kind, int ticks) {
    switch (kind) {
      case DotKind.veneno:
        return Dot._(
          kind: kind,
          tipo: CreatureType.planta,
          dano: 1.0,
          intervalo: 1.0,
          cor: Palette.verde,
          tetoTicks: 6,
          acumula: true,
          ticks: ticks,
        );
      case DotKind.queimadura:
        return Dot._(
          kind: kind,
          tipo: CreatureType.fogo,
          dano: 2.0,
          intervalo: 0.35,
          cor: Palette.laranja,
          tetoTicks: 3,
          acumula: false,
          ticks: ticks,
        );
    }
  }

  void reaplicar(int novosTicks) {
    if (acumula) {
      ticks = (ticks + novosTicks).clamp(0, tetoTicks);
    } else if (novosTicks > ticks) {
      ticks = novosTicks.clamp(0, tetoTicks);
    }
  }
}
