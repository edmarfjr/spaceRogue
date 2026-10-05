import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:flame/components.dart';

/// Quem pode ser vítima de dano inimigo (projétil, explosão, bomba). Ver
/// PIVOT_TREINADOR.md §3.3: o treinador (`Player`) e cada `Companion` do
/// grupo entram aqui, substituindo o antigo teste `other is Player` nos três
/// pontos de dano (`Projectile`, `ExplosionHitbox`, `Bomb`).
mixin DamageableByEnemy on PositionComponent {
  /// [origem] é a criatura que causou o golpe, e [porArmadilha] marca dano
  /// do cenário — os dois só servem pro "derrotado por" do resumo de Game
  /// Over. Ausentes, o golpe conta igual e o resumo apenas omite a linha.
  void takeDamage(
    double amount,
    CreatureType tipoAtacante, {
    CreatureData? origem,
    bool porArmadilha = false,
  });

  /// Reaplicar renova a duração e fica com o fator mais forte — nunca
  /// multiplica um sobre o outro, mesma regra do `Enemy`.
  void aplicarLentidao(double duracao, {double fator = 0.5});

  void aplicarCegueira(double duracao);

  void applyKnockback(Vector2 sourcePosition, double force);

  bool get refleteProjetil;
}
