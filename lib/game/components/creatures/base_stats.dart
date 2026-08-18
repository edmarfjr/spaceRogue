class BaseStats {
  final int maxHp;
  final double speed;
  final double defesa;
  final double ataque;

  const BaseStats({
    required this.maxHp,
    required this.speed,
    required this.defesa,
    required this.ataque,
  });

  /// Aplica a redução de defesa sobre um dano bruto, com piso de 1.
  double danoRecebido(double danoBruto) {
    final reduzido = danoBruto * (1 - defesa * 0.08);
    return reduzido < 1 ? 1 : reduzido;
  }
}
