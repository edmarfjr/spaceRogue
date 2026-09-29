import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

/// Evolução de [VooAlto]: o voo continua invulnerável, mas agora MACHUCA
/// quem ele atravessa.
///
/// O dano sai no CAMINHO, não no pouso. Todo o resto do elenco que bate ao
/// se esquivar bate no fim (Rastro Flamejante explode onde chegou, Salto
/// Aquático respinga ao aterrissar), então acertar ao longo da linha é um
/// espaço que ninguém ocupa — e é exatamente o que um bombardeio de mergulho
/// deveria parecer.
///
/// Reaproveita `Player.danoDeContato`, o canal que já existe pra "meu corpo
/// machuca quem encosta" (ver `RodaDeFogo`). Ele traz de graça a trava de
/// reacerto por inimigo, sem a qual um inimigo grudado no trajeto levaria
/// dano a 60fps.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class VooAltoEvo extends Ability {
  final double distancia;
  final double duracao;
  final double coef;

  const VooAltoEvo({this.distancia = 64, this.duracao = 0.3, this.coef = 1.4})
    : super(
        nome: 'Vôo Rasante',
        descricao: 'Voo invulnerável que fere quem estiver no caminho.',
        cooldown: 3.5,
        target: AbilityTarget.plrDir,
        tipo: AbilityTipo.esquiva,
      );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantInvulnerability(duracao);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    // O canal de dano de contato é do `Player`; o `Companion` não tem. Sem
    // este teste a evolução quebraria a forma companion da criatura.
    if (user is Player) {
      final player = user;
      final danoAnterior = player.danoDeContato;
      player.danoDeContato = player.creatureData.stats.ataque * coef;
      // Devolve o valor ANTERIOR, e não zero: uma passiva ou item pode ter
      // ligado o dano de contato por conta própria, e zerar aqui apagaria
      // aquilo sem ninguém pedir.
      player.aplicarEfeito(
        #vooRasante,
        duracao,
        aoTerminar: () => player.danoDeContato = danoAnterior,
      );
    }

    user.add(
      MoveByEffect(
        user.dashOffsetLivre(dir, distancia),
        EffectController(duration: duracao),
      ),
    );
  }
}
