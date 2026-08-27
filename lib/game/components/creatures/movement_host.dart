import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/effects/sprite_effect.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';

/// Contrato que os cinco mixins de IA em `enemy_mixins.dart`
/// (`GridMovement`, `WanderMovement`, `ShooterAttack`, `ChaseMovement`,
/// `JumpMovement`) precisam de quem os usa. Extraído de `Enemy` — ver
/// PIVOT_TREINADOR.md §3.1 — para que `Companion` reuse os mesmos cinco
/// comportamentos sem reescrever IA nenhuma.
///
/// `on PositionComponent` pelo mesmo motivo de `AbilityUser`: os mixins usam
/// `position`/`absolutePosition`/`size`/`parent` de `PositionComponent`
/// diretamente, sem precisar redeclará-los aqui.
mixin MovementHost on PositionComponent {
  double get speed;

  SpriteComponent get visual;

  RectangleHitbox get enemyHitbox;
  RectangleHitbox get physicsHitbox;

  /// Quem este ator persegue/mira quando o comportamento é de perseguição
  /// (ver `ChaseMovement`). Em `Enemy` é sempre o treinador; em `Companion`,
  /// depende da natureza.
  PositionComponent get currentTarget;

  /// Toca a animação de movimento genérica do host (ver `MovementAnimator`).
  /// Cada host mantém seu próprio animador — não há estado comum aqui.
  void animateMovement(double dt, {required bool isMoving, double horizontalDir = 0.0});

  Vector2 knockbackVelocity = Vector2.zero();
  bool isAirborne = false;
  double lentidaoFator = 1.0;
  double cegoTimer = 0.0;

  void spawnAlerta({double duracao = 0.5}) {
    final effect = SpriteEffect(
      position: position.clone() - Vector2(0, size.y),
      size: Vector2(16, 16),
      corClara: Palette.indigo,
      corEscura: Palette.vermelho,
      corBranco: Palette.branco,
      spritePath: 'effects/exclamacao.png',
      textureSize: Vector2(16, 16),
      stepTime: duracao,
    );
    parent?.add(effect);
  }

  RoomComponent? _cachedRoom;

  /// A sala onde este ator está. Cacheada porque paredes e a maioria dos
  /// obstáculos são netos do World (filhos de RoomComponent) — varrer
  /// `parent!.children` toda hora não encontraria nada.
  RoomComponent? get currentRoom {
    final center = Offset(absolutePosition.x, absolutePosition.y);

    final cached = _cachedRoom;
    if (cached != null && cached.isMounted && cached.toAbsoluteRect().contains(center)) {
      return cached;
    }

    final p = parent;
    if (p == null) return null;

    for (final room in p.children.whereType<RoomComponent>()) {
      if (room.toAbsoluteRect().contains(center)) {
        _cachedRoom = room;
        return room;
      }
    }

    _cachedRoom = null;
    return null;
  }

  /// Todos os corpos sólidos da sala atual (paredes, pedras, buracos, portas).
  Iterable<PositionComponent> get roomColliders {
    final room = currentRoom;
    if (room == null) return const [];

    final localColliders = room.children
        .whereType<PositionComponent>()
        .where((c) => c is WallBarrier || c is Obstacle);

    final p = parent;
    final worldRocks = p == null
        ? const <Rock>[]
        : p.children.whereType<Rock>().where(
            (r) => room.toAbsoluteRect().overlaps(r.toAbsoluteRect()),
          );

    return localColliders.followedBy(worldRocks);
  }

  /// Há alguma parede ou obstáculo no caminho se andar em [dir] pelos
  /// próximos [segundos]?
  bool direcaoLivre(Vector2 dir, {double segundos = 0.6}) {
    final room = currentRoom;
    if (room == null) return true;

    final double lookAheadDistance = speed * segundos;
    final Vector2 futureCenter = physicsHitbox.absoluteCenter + (dir * lookAheadDistance);

    final Rect futureRect = Rect.fromCenter(
      center: Offset(futureCenter.x, futureCenter.y),
      width: physicsHitbox.size.x,
      height: physicsHitbox.size.y,
    );

    for (final child in roomColliders) {
      if (isAirborne && child is Obstacle) continue;
      if (child.toAbsoluteRect().overlaps(futureRect)) return false;
    }

    return true;
  }
}
