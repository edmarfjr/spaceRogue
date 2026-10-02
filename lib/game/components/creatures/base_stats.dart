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

  /// Chance, em PORCENTO, de o golpe errar por completo — ver
  /// `Player.takeDamage`, que é quem rola o dado.
  ///
  /// Porcento, e não fração de 0 a 1, pela mesma razão do `critBonus` e do
  /// `Player.critChance`: todo número de chance do jogo já está em porcento, e
  /// misturar as duas escalas é como se erra um balanceamento por um fator de
  /// cem sem ninguém notar.
  ///
  /// 5% em todo mundo por padrão: baixo o bastante pra não ser estratégia
  /// sozinho, alto o bastante pra o jogador ver acontecer numa run.
  final double evasao;

  const BaseStats({
    required this.maxHp,
    required this.speed,
    this.tempoAteMaxima = 0.3,
    this.tempoAteParar = 0.2,
    required this.defesa,
    required this.ataque,
    this.critBonus = 0.0,
    this.evasao = evasaoPadrao,
  });

  /// Evasão de quem não declara a sua.
  static const double evasaoPadrao = 5.0;

  double get shieldMax => defesa * 1.0;
}
