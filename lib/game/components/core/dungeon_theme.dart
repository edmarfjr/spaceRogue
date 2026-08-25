import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart'; 

class DungeonTheme {
  final Color corClara;
  final Color corEscura;
  final Color corBranca;

  const DungeonTheme({
    required this.corClara,
    required this.corEscura,
    this.corBranca = Palette.branco,
  });

  static const List<DungeonTheme> levelThemes = [
    DungeonTheme(
      corClara: Palette.verde, 
      corEscura: Palette.verdeEsc,
      corBranca: Palette.branco,
    ),
    /*DungeonTheme(
      corClara: Palette.marromEsc, 
      corEscura: Palette.chocolate,
      corBranca: Palette.pumpkin,
    ),
    DungeonTheme(
      corClara: Palette.verdeEsc, 
      corEscura: Palette.forest,
      corBranca:Palette.verde
    ),
    DungeonTheme(
      corClara: Palette.azul, 
      corEscura: Palette.azulEsc,
    ),
    DungeonTheme(
      corClara: Palette.vermelho, 
      corEscura: Palette.burgundy,
    ),
    DungeonTheme(
      corClara: Palette.cinza, 
      corEscura: Palette.preto,
    ),
    */
  ];

  static DungeonTheme getThemeForLevel(int level) {
    int index = (level - 1) % levelThemes.length;
    return levelThemes[index];
  }
}