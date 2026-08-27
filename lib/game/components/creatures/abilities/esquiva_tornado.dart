import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Tornado de Fogo — botão B. Evasiva com i-frames, deixa rastro de dano.
/// Dano = ataque da criatura × [coefRastro] — ver BaseStats.
class EsquivaTornado extends Ability {
  final double distancia;
  final double duracao;
  final double coefRastro;

  const EsquivaTornado({
    this.distancia = 32,
    this.duracao = 0.15,
    this.coefRastro = 0.5,
  }) : super(nome: 'Esquiva Tornado', cooldown: 4.0, target: AbilityTarget.plrDir, tipo: AbilityTipo.esquiva);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final danoRastro = user.creatureData.stats.ataque * coefRastro;
    user.grantInvulnerability(duracao);

    user.parent?.add(Projectile(
          position: user.position.clone(),
          direction: Vector2.zero(),
          speed:0,
          lifeTime: 3,
          dmg: danoRastro,
          sprPath: 'projeteis/tornado.png',
          cor1: Palette.vermelho,
          cor2: Palette.laranja,
          tipo: user.creatureData.tipo,
          radius: 8,
          atravessa: 10
        ));

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(MoveByEffect(
      -dir.normalized() * distancia,
      EffectController(duration: duracao),
      onComplete: () {
        
      },
    ));
  }
}
