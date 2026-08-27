/// Stats do treinador, separados de `CreatureData`/`BaseStats` desde
/// PIVOT_TREINADOR.md §3.7: o treinador não é mais uma criatura (não tem tipo
/// elemental, não some quando o companion desmaia), então `maxHealth` e
/// `speed` não podem continuar derivando de `creatureData.stats` — com grupo
/// de três (fase 5b) nem haveria uma criatura única de onde vir.
///
/// Sem `defesa` como em `BaseStats`: só existe um treinador, então
/// `shieldMax` é um valor direto, sem a derivação `defesa * 2.0` que faz
/// sentido quando dezesseis criaturas compartilham a mesma fórmula.
///
/// Valores um primeiro corte, não tunados por playtest — mesmo padrão usado
/// pro resto do rebalanceamento desta rodada.
class TrainerStats {
  final double maxHealth;
  final double speed;
  final double shieldMax;

  /// Alcance do laço de captura (PIVOT_TREINADOR.md §4.1): distância máxima
  /// pra travar um alvo E pra manter o laço travado depois (regra de quebra
  /// #2). Maior que o raio da volta (24px, fixo — ver `Player.captureOrbitRadius`)
  /// pra sobrar folga: sem essa folga, qualquer imperfeição na volta já
  /// quebraria o laço sozinho.
  ///
  /// Em 80 pra TESTE (era 40 — só 16px de folga sobre os 24px do raio, e
  /// andar uma volta de verdade, principalmente pelo teclado direcional de 8
  /// direções, não traça um círculo perfeito). Com pouca folga, qualquer
  /// imprecisão do jogador estourava a distância, cancelava o laço, e o
  /// alvo elegível mais próximo (o mesmo de novo, quase sempre) reabria um
  /// na hora — lido como "o laço fica saindo e voltando". Reapertar depois
  /// que a volta em si estiver validada.
  final double captureRange;

  const TrainerStats({
    this.maxHealth = 4,
    this.speed = 60,
    this.shieldMax = 2,
    this.captureRange = 80,
  });

  static const TrainerStats padrao = TrainerStats();
}
