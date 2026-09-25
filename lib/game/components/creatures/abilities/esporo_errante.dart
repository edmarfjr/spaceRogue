import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Cogumelo de Planta — botão A. Solta um esporo que vai pro MESMO lado que o
/// jogador está indo, mais rápido que ele, e para quando o jogador para.
///
/// Não tem mira: a direção não vem do analógico de ataque, vem de para onde
/// você anda. É uma arma de condução, não de pontaria — você empurra o esporo
/// pelo campo andando, e o segura no lugar parando.
///
/// O modo `ProjetilMovimento.dirigidoPeloDono` lê a DIFERENÇA de posição do
/// dono entre quadros, não a `velocity` dele. Isso importa aqui: as esquivas
/// do jogo se movem por `MoveByEffect`, que não encosta em `velocity`, e pela
/// velocidade o esporo ficaria parado durante toda disparada.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class EsporoErrante extends Ability {
  final double coef;

  /// Velocidade PRÓPRIA do esporo. Acima da velocidade de qualquer criatura
  /// (25 a 110, ver o registro) pra ele ir na frente em vez de ser arrastado
  /// junto — senão o jogador nunca o veria acertar nada.
  final double velocidade;

  final double duracao;
  final int ticksVeneno;

  const EsporoErrante({
    this.coef = 0.8,
    this.velocidade = 80,
    this.duracao = 5.0,
    this.ticksVeneno = 2,
  }) : super(
         nome: 'Esporo Errante',
         descricao:
             'Esporo que segue a direção do seu movimento e para quando você para.',
         cooldown: 0.4,
         custoEnergia: 2.5,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(
      Projectile(
        owner: user,
        position: user.position.clone() + dir*16,
        // Direção inicial só pra o sprite nascer virado: quem manda a partir
        // do primeiro quadro é o movimento do dono.
        direction: dir,
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
      ),
    );
  }
}
