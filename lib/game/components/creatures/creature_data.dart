import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../effects/movement_animator.dart';
import '../enemies/enemy.dart';
import '../player/player.dart';
import 'ability.dart';
import 'base_stats.dart';
import 'creature_type.dart';

typedef EnemyBuilder = Enemy Function(Vector2 position, Player playerTarget);

class CreatureData {
  final String id;
  final String nome;
  final String spritePath;
  final CreatureType tipo;
  final Color corClara;
  final Color corEscura;
  final BaseStats stats;
  final Ability ability1;
  final Ability ability2;

  /// Estilo de animação do sprite enquanto anda (ver MovementAnimator).
  final MovementAnimation moveAnim;

  /// Tamanho do colisor de combate (e, proporcionalmente, do colisor de
  /// física e da sombra). Cada criatura tem o seu — a tartaruga é mais larga
  /// que o roedor, por exemplo.
  final Vector2 hitboxSize;

  /// Comportamento desta criatura quando aparece como inimigo.
  /// Ainda não existe para as 4 criaturas iniciais — ver PIVOT_CRIATURAS.md, fase 4.
  final EnemyBuilder? enemyBuilder;

  const CreatureData({
    required this.id,
    required this.nome,
    required this.spritePath,
    required this.tipo,
    required this.corClara,
    required this.corEscura,
    required this.stats,
    required this.ability1,
    required this.ability2,
    required this.moveAnim,
    required this.hitboxSize,
    this.enemyBuilder,
  });
}
