enum CreatureType { fogo, planta, agua, eletrico, neutro }

const Map<CreatureType, CreatureType> _vantagens = {
  CreatureType.fogo: CreatureType.planta,
  CreatureType.planta: CreatureType.agua,
  CreatureType.agua: CreatureType.fogo,
  CreatureType.eletrico: CreatureType.agua,
};

const Map<CreatureType, CreatureType> _desvantagens = {
  CreatureType.fogo: CreatureType.agua,
  CreatureType.planta: CreatureType.fogo,
  CreatureType.agua: CreatureType.eletrico,
  CreatureType.eletrico: CreatureType.planta,
};

/// Multiplicador de dano de [atacante] contra [defensor].
double typeMultiplier(CreatureType atacante, CreatureType defensor) {
  if (_vantagens[atacante] == defensor) return 1.5;
  if (_desvantagens[atacante] == defensor) return 0.75;
  return 1.0;
}
