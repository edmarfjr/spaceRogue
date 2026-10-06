import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esguicho_de_tinta.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';

/// Evolução de [EsguichoDeTinta]: a nuvem fica maior, dura mais e passa a
/// ENGOLIR projéteis inimigos que a atravessam — inclusive os que teriam
/// vantagem de tipo sobre a água. Vira cortina: esquivar deixa um escudo pra
/// trás.
class CortinaDeTinta extends Ability {
  final double distancia;
  final double duracao;
  final double cegueira;
  final double vidaNuvem;

  const CortinaDeTinta({
    this.distancia = 48,
    this.duracao = 0.15,
    this.cegueira = 1.5,
    this.vidaNuvem = 4.0,
  }) : super(
         nome: 'Cortina de Tinta',
         descricao:
             'Esquiva que deixa uma nuvem de tinta que cega e bloqueia projéteis.',
         cooldown: 4.0,
         target: AbilityTarget.plrDir,
         tipo: AbilityTipo.esquiva,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantInvulnerability(duracao);
    user.parent?.add(
      EsguichoDeTinta.nuvem(
        dono: user,
        posicao: user.position.clone(),
        cegueira: cegueira,
        vida: vidaNuvem,
        lado: 32,
        bloqueiaTiro: true,
      ),
    );
    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );
    user.add(
      MoveByEffect(
        user.dashOffsetLivre(dir, distancia),
        EffectController(duration: duracao),
      ),
    );
  }
}
