import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'creature_data.dart';

/// Contrato que uma habilidade (Ability) precisa de quem a executa. Tanto
/// `Player` quanto `Companion` (ver PIVOT_TREINADOR.md) usam este mixin — é o
/// que permite que a mesma instância stateless de `Ability` sirva à forma
/// jogável e à forma companion sem duplicar as 31 classes de habilidade.
///
/// `on PositionComponent` porque várias habilidades chamam `user.add(...)`,
/// leem `user.parent`/`user.position`/`user.size`/`user.isMounted` — membros
/// de `Component`/`PositionComponent` que não fazem sentido redeclarar aqui.
mixin AbilityUser on PositionComponent {
  CreatureData get creatureData;

  SpriteComponent get visual;

  /// Mira travada de cada botão: o inimigo mais próximo, ou a direção do
  /// movimento/corpo, conforme `Ability.target`. Cada `AbilityUser` calcula a
  /// própria (Player a partir de si mesmo; Companion a partir de si mesmo).
  Vector2 get lockedAb1Direction;
  Vector2 get lockedAb2Direction;

  /// Bombas são recurso do treinador (ver PIVOT_TREINADOR.md §3.2): mesmo
  /// quando quem executa é um Companion, `bombsAmount` e `placeBomb` sempre
  /// resolvem para o contador do treinador.
  int get bombsAmount;
  void placeBomb(Vector2 dir);

  void grantInvulnerability(double seconds);

  void startJump({
    required Vector2 direction,
    required double distance,
    required double duration,
    double height = 16.0,
    VoidCallback? onLand,
  });

  // --- Ganchos usados pelas habilidades das criaturas ---
  // Neutros por padrão: nada muda enquanto nenhuma habilidade os usa.
  bool shieldVisualActive = false;
  bool speedLocked = false;
  int shieldHits = 0;
  double damageReduction = 0.0;
  bool refleteProjetil = false;

  /// Ouriço Elétrico — enquanto true, cada golpe absorvido por [shieldHits]
  /// dispara uma explosão elétrica em volta do usuário (ver Escudo de Espinhos).
  bool retaliaEspinhos = false;
  double retaliaDano = 0.0;
  double retaliaStunDuration = 0.0;
}
