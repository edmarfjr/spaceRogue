class BaseStats {
  final double maxHp;
  final double speed;
  /// Segundos pra ir de parado ate a velocidade maxima, e pra voltar de la
  /// ate parado.
  ///
  /// TEMPO, e nao aceleracao em px/s2, por dois motivos concretos:
  ///
  /// 1. Uma aceleracao FIXA da tempos diferentes pra cada criatura, porque o
  ///    tempo e `maxSpeed / aceleracao` e `speed` vai de 25 a 110. Pra dar
  ///    0,3s em todas era preciso um valor por criatura (de 83 a 367),
  ///    calculado na mao a cada criatura nova.
  /// 2. `maxSpeed` ja desconta lentidao, grama alta e o upgrade de
  ///    velocidade. Com tempo, a rampa continua a mesma nesses estados; com
  ///    aceleracao fixa, pisar na grama alta cortava `maxSpeed` pela metade e
  ///    a rampa virava metade do tempo.
  ///
  /// Quem converte pra aceleracao e `Player.acceleration`/`Player.friction`.
  final double tempoAteMaxima;
  final double tempoAteParar;

  final double defesa;
  final double ataque;
  final double critBonus;

  const BaseStats({
    required this.maxHp,
    required this.speed,
    this.tempoAteMaxima = 0.3,
    this.tempoAteParar = 0.3,
    required this.defesa,
    required this.ataque,
    this.critBonus = 0.0,
  });

  double get shieldMax => defesa * 1.0;
}
