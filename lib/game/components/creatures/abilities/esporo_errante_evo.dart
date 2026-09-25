import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [EsporoErrante]: TRÊS esporos em leque, todos conduzidos pelo
/// mesmo movimento.
///
/// Leque, e não um esporo mais forte, porque o gargalo da forma base não é
/// dano, é ACERTO: o esporo não mira, e conduzir um só até um inimigo que
/// anda exige adivinhar a rota dele. Três lado a lado perdoam o erro de
/// leitura sem tirar a condução, que é a identidade da criatura.
///
/// O leque é montado deslocando o ponto de NASCIMENTO na perpendicular, e não
/// abrindo ângulos diferentes: os três compartilham a direção do dono a cada
/// quadro, então ângulo inicial diferente seria apagado no primeiro passo.
class EsporoErranteEvo extends Ability {
  final double coef;
  final double velocidade;
  final double duracao;
  final int ticksVeneno;

  /// Distância entre um esporo e o do lado, medida na perpendicular da mira
  /// inicial.
  final double separacao;

  const EsporoErranteEvo({
    this.coef = 0.65,
    this.velocidade = 80,
    this.duracao = 6.5,
    this.ticksVeneno = 3,
    this.separacao = 9,
  }) : super(
         nome: 'Nuvem Errante',
         descricao:
             'Três esporos lado a lado, conduzidos pela direção do seu movimento.',
         cooldown: 0.4,
         custoEnergia: 3.0,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    // `coef` abaixo do da base (0,65 contra 0,8): quem consegue passar os três
    // pelo mesmo alvo soma quase o dobro, e quem acerta só um perde pouco.
    final dano = user.creatureData.stats.ataque * coef;
    final frente = dir.length == 0 ? Vector2(0, -1) : dir.normalized();
    final lado = Vector2(-frente.y, frente.x);

    for (final desvio in [-1.0, 0.0, 1.0]) {
      user.parent?.add(
        Projectile(
          owner: user,
          position: user.position.clone() + lado * desvio * separacao,
          direction: frente,
          speed: velocidade,
          movimento: ProjetilMovimento.dirigidoPeloDono,
          dmg: dano,
          lifeTime: duracao,
          sprPath: 'projeteis/nuvemP.png',
          cor1: user.creatureData.corClara,
          cor2: user.creatureData.corEscura,
          tipo: user.creatureData.tipo,
          dotKind: DotKind.veneno,
          dotTicks: ticksVeneno,
          radius: 7,
          // Só o do meio toca som: três no mesmo quadro estouram o throttle
          // do `GameAudio` e saem como um estalo sujo.
          playSfx: desvio == 0.0,
        ),
      );
    }
  }
}
