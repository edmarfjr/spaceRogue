import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../effects/movement_animator.dart';
import '../enemies/enemy.dart';
import '../player/player.dart';
import 'ability.dart';
import 'base_stats.dart';
import 'creature_type.dart';
import 'passive.dart';

typedef EnemyBuilder = Enemy Function(Vector2 position, Player playerTarget);

/// Como esta criatura se comporta como `Companion` (ver PIVOT_TREINADOR.md
/// §3.6). `guarda`: fica na coleira do treinador. `cacador`: persegue o
/// hostil mais próximo sem coleira enquanto houver um na sala, senão volta a
/// se comportar como `guarda`. `orbital`: circula em volta do treinador a
/// raio fixo, sem nunca perseguir ninguém.
enum CompanionBehavior { guarda, cacador, orbital }

class CreatureData {
  final String id;
  final String nome;
  final String spritePath;
  final CreatureType tipo;
  final Color corClara;
  final Color corEscura;
  final BaseStats stats;
  final Ability ability1;

  /// Habilidade B original — sem execução própria desde que o companion
  /// passou a disparar só `ability1` autonomamente (ver PIVOT_TREINADOR.md).
  /// Mantida no dado: guarda a intenção original de cada criatura, e é a
  /// referência que cada `Passive` correspondente porta pra baixo (ver
  /// `creatures/passives/`).
  final Ability ability2;

  /// Habilidade passiva desta criatura (substitui `ability2` como algo que
  /// de fato acontece) — vale enquanto ela estiver no grupo do treinador,
  /// capturada ou não, no bolso ou fora dele. Ver `Passive`.
  final Passive passive;

  /// Estilo de animação do sprite enquanto anda (ver MovementAnimator).
  final MovementAnimation moveAnim;

  /// Tamanho do colisor de combate (e, proporcionalmente, do colisor de
  /// física e da sombra). Cada criatura tem o seu — a tartaruga é mais larga
  /// que o roedor, por exemplo.
  final Vector2 hitboxSize;

  /// Comportamento desta criatura quando aparece como inimigo.
  /// Ainda não existe para as 4 criaturas iniciais — ver PIVOT_CRIATURAS.md, fase 4.
  final EnemyBuilder? enemyBuilder;

  /// Natureza como companion (ver PIVOT_TREINADOR.md §3.6). Default `guarda`
  /// pra não obrigar as 16 entradas do registry a declarar isso — só as que
  /// têm um motivo pra ser diferente precisam sobrescrever.
  final CompanionBehavior companionBehavior;

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
    required this.passive,
    required this.moveAnim,
    required this.hitboxSize,
    this.enemyBuilder,
    this.companionBehavior = CompanionBehavior.guarda,
  });
}
