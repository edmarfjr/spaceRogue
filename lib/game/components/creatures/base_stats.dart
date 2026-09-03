class BaseStats {
  final double maxHp;
  final double speed;
  final double defesa;
  final double ataque;

  const BaseStats({
    required this.maxHp,
    required this.speed,
    required this.defesa,
    required this.ataque,
  });

  double get shieldMax => defesa * 1.0;
}
