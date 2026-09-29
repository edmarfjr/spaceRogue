import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Evolução de [SaltoFelino]: salto mais longo, o arranhão de pouso vira um
/// círculo completo, e o pouso deixa a criatura acelerada por um instante.
///
/// As três partes atacam a MESMA fraqueza. O Meao é a criatura mais lenta do
/// elenco jogável (speed 45), então cada uso do botão B é a única janela de
/// reposicionamento que ele tem. O salto maior leva mais longe, o círculo
/// não exige acertar a mira no pouso, e a janela de cadência transforma o
/// pouso em abertura de ataque em vez de um tempo morto.
///
/// A cadência entra pelo par `aoIniciar`/`aoTerminar` sobre o `cdMult`, mesma
/// receita do item Desesperado — `limparEfeitos` na troca de criatura e na
/// troca de andar desfaz o par, então o bônus não atravessa o save.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class SaltoFelinoEvo extends Ability {
  final double distancia;
  final double duracao;
  final double coef;

  /// Lado do círculo de pouso. Bem maior que os 24 da forma base: é ele que
  /// dispensa a mira.
  final double raioPouso;

  /// Quanto tempo a cadência fica acelerada depois de pousar.
  final double janelaCadencia;

  /// Multiplicador do `cdMult` na janela — abaixo de 1 é mais rápido.
  final double fatorCadencia;

  const SaltoFelinoEvo({
    this.distancia = 56,
    this.duracao = 0.2,
    this.coef = 1.2,
    this.raioPouso = 40,
    this.janelaCadencia = 1.0,
    this.fatorCadencia = 0.6,
  }) : super(
         nome: 'Bote Felino',
         descricao:
             'Salto longo e invulnerável; o pouso corta em volta e acelera '
             'seu ataque.',
         cooldown: 3.0,
         target: AbilityTarget.plrDir,
         tipo: AbilityTipo.esquiva,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.grantInvulnerability(duracao);

    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );

    user.add(
      MoveByEffect(
        user.dashOffsetLivre(dir, distancia),
        EffectController(duration: duracao),
        onComplete: () {
          user.parent?.add(
            ExplosionHitbox(
              position: user.position.clone(),
              dmg: dano,
              tipo: user.creatureData.tipo,
              size: Vector2.all(raioPouso),
            ),
          );

          // `cdMult` é campo do Player; o Companion não tem essa engrenagem.
          if (user is! Player) return;
          final player = user;
          player.aplicarEfeito(
            #botefelino,
            janelaCadencia,
            aoIniciar: () => player.cdMult *= fatorCadencia,
            aoTerminar: () => player.cdMult /= fatorCadencia,
          );
        },
      ),
    );
  }
}
