class BaseStats {
  final double maxHp;
  final double speed;
  final double defesa;
  final double ataque;
  final double critBonus;

  const BaseStats({
    required this.maxHp,
    required this.speed,
    required this.defesa,
    required this.ataque,
    this.critBonus = 0.0,
  });

  double get shieldMax => defesa * 1.0;
}
