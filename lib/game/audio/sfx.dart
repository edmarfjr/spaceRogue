import 'package:creatures_rogue/game/components/creatures/creature_type.dart';

/// Efeitos sonoros do jogo. Cada valor mapeia pra um arquivo em
/// `assets/sounds/sfx/` (ver `GameAudio._paths`) — adicionar um som novo é só
/// acrescentar aqui e no mapa.
enum Sfx {
  dash,
  retorno,
  liberar,
  enemy_die,
  btn,
  stairs,
  die,
  hit,
  fogo,
  agua,
  raio,
  veneno,
  pick,
  use,
}

/// Som de ataque elemental de cada [CreatureType] — usado nos pontos onde o
/// dano de fato sai (`ExplosionHitbox`/`Projectile`), não em cada `Ability`
/// individualmente. `neutro` não tem som próprio.
extension CreatureTypeSfx on CreatureType {
  Sfx? get attackSfx => switch (this) {
        CreatureType.fogo => Sfx.fogo,
        CreatureType.agua => Sfx.agua,
        CreatureType.eletrico => Sfx.raio,
        CreatureType.planta => Sfx.veneno,
        CreatureType.neutro => null,
      };
}
