import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [BicoEletrico] (ver `PIVOT_EVOLUCAO`): cada bicada agora cega
/// por um instante (`cegoDuracao`) — o volume de disparos da Ave evoluída
/// vem acompanhado de um choque que atrapalha a mira de quem é atingido.
class BicoEletricoEvo extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;
  final double cegoDuracao;

  const BicoEletricoEvo({
    this.coef = 1.1,
    this.velocidade = 260,
    this.alcanceSegundos = 0.25,
    this.cegoDuracao = 0.6,
  }) : super(nome: 'Bico Elétrico+', cooldown: 0.2);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(
      Projectile(
        owner: user,
        position: user.position.clone(),
        direction: dir,
        speed: velocidade,
        dmg: dano,
        sprPath: 'projeteis/proj2.png',
        lifeTime: alcanceSegundos,
        cegoDuracao: cegoDuracao,
        cor1: Palette.amarelo,
        cor2: Palette.laranja,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
