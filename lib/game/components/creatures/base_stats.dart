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

  /// Tamanho do escudo passivo (segunda barra, absorve antes do HP) — quanto
  /// maior a defesa, mais escudo. Regenera com o tempo; a taxa é do Player,
  /// não daqui, porque upgrades/itens futuros vão alterá-la em runtime.
  double get shieldMax => defesa * 2.0;
}
