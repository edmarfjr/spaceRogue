import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [Arranhao]: dois golpes cruzados em X em vez de um só.
///
/// Dois, e não três em leque: com três o arranhão vira um cone, e o Meao
/// deixaria de ser a criatura que precisa ENCOSTAR pra bater — que é a
/// tensão dele, já que também é a mais lenta do elenco. Dois traços abertos
/// perdoam a mira sem virar alcance.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class ArranhaoEvo extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  /// Abertura de cada traço em relação à mira, em fração da perpendicular.
  final double abertura;

  const ArranhaoEvo({
    this.coef = 0.9,
    this.velocidade = 240,
    this.alcanceSegundos = 0.18,
    this.abertura = 0.45,
  }) : super(
         nome: 'Garras Cruzadas',
         descricao: 'Dois golpes cruzados, de curto alcance e alta cadência.',
         cooldown: 0.2,
         custoEnergia: 1.6,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final frente = dir.length == 0 ? Vector2(0, 1) : dir.normalized();
    final lado = Vector2(-frente.y, frente.x);

    for (final desvio in [-1.0, 1.0]) {
      user.parent?.add(
        Projectile(
          owner: user,
          position: user.position.clone(),
          direction: (frente + lado * desvio * abertura).normalized(),
          speed: velocidade,
          dmg: dano,
          lifeTime: alcanceSegundos,
          sprPath: 'projeteis/proj2.png',
          cor1: user.creatureData.corClara,
          cor2: user.creatureData.corEscura,
          tipo: user.creatureData.tipo,
          // Só um dos dois toca som: dois disparos no mesmo quadro estouram o
          // throttle do `GameAudio` e saem como um estalo sujo.
          playSfx: desvio < 0,
        ),
      );
    }
  }
}
