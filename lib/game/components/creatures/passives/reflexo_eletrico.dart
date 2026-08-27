import '../passive.dart';

/// Grilo Elétrico — antes era `DisparadaVeloz` (botão B). Puramente
/// numérico: a esquiva do treinador fica mais curta e recarrega bem mais
/// rápido, do jeito que a esquiva original do Grilo era (distância 24 contra
/// os 30 padrão, cooldown 1.0 contra 1.1). Sem hook nenhum — só os
/// multiplicadores da base `Passive`, lidos direto por `Player.dodge`.
class ReflexoEletrico extends Passive {
  const ReflexoEletrico()
      : super(
          nome: 'Reflexo Elétrico',
          descricao: 'A esquiva do treinador recarrega bem mais rápido, mas percorre menos distância.',
          dodgeCooldownMult: 0.6,
          dodgeDistanceMult: 0.8,
        );
}
