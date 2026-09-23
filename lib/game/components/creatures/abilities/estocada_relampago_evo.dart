import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [EstocadaRelampago]: três lanças paralelas em vez de uma.
///
/// Paralelas, e não em leque: o que define o Leão no elenco elétrico é bater
/// de LONGE numa linha, enquanto o resto investe de corpo. Abrir em leque
/// transformaria a habilidade num tiro de perto e apagaria essa diferença.
/// Três linhas lado a lado mantêm o alcance e só perdoam a mira imprecisa.
///
/// Cada lança segue atravessando, então uma fila de inimigos alinhada com o
/// disparo leva as três.
class EstocadaRelampagoEvo extends Ability {
  final double coef;
  final double velocidade;
  final int atravessa;

  /// Distância entre as lanças, medida na perpendicular da mira.
  final double separacao;

  const EstocadaRelampagoEvo({
    this.coef = 0.75,
    this.velocidade = 180,
    this.atravessa = 3,
    this.separacao = 7,
  }) : super(
         nome: 'Tridente Relâmpago',
         descricao: 'Três lanças paralelas que atravessam alvos em linha.',
         cooldown: 1.4,
         custoEnergia: 5.0,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    // `coef` abaixo do da base (0,75 contra 0,9): quem acerta com as três
    // linhas soma 2,25 do ataque, e errar duas ainda rende quase uma estocada
    // antiga.
    final dano = user.creatureData.stats.ataque * coef;
    final frente = dir.normalized();
    // Perpendicular no plano da tela — é ela que espalha as lanças de lado
    // sem mudar a direção de nenhuma.
    final lado = Vector2(-frente.y, frente.x);

    for (final desvio in [-1.0, 0.0, 1.0]) {
      user.parent?.add(
        Projectile(
          owner: user,
          position:
              user.position.clone() +
              frente * user.size.x / 2 +
              lado * desvio * separacao,
          direction: frente,
          speed: velocidade,
          dmg: dano,
          atravessa: atravessa,
          sprPath: 'projeteis/proj2.png',
          cor1: user.creatureData.corClara,
          cor2: user.creatureData.corEscura,
          tipo: user.creatureData.tipo,
          // Só a lança do meio toca som: três disparos no mesmo quadro
          // estouram o throttle do `GameAudio` e saem como um estalo sujo.
          playSfx: desvio == 0.0,
        ),
      );
    }
  }
}
