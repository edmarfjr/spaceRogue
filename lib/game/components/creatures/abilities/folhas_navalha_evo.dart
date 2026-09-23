import 'dart:math';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/orbit_projectile.dart';

/// Evolução de [FolhasNavalha]: dois anéis girando em sentidos OPOSTOS.
///
/// Não é só "mais espinhos". Um anel só, por mais cheio que fique, tem sempre
/// a mesma brecha girando junto — quem entra no compasso passa. Dois anéis
/// contrários fecham a brecha, porque o vão de um cruza o espinho do outro, e
/// o anel de fora ainda alarga a zona que o Toco controla sem sair do lugar.
///
/// A contra-rotação sai de graça: `OrbitProjectile` só soma
/// `velocidadeAngular` no ângulo a cada quadro, então um valor negativo já
/// gira pro outro lado.
class FolhasNavalhaEvo extends Ability {
  final double coef;
  final int porAnel;
  final double raioInterno;
  final double raioExterno;
  final double velocidadeAngular;
  final double duracao;

  const FolhasNavalhaEvo({
    this.coef = 0.4,
    this.porAnel = 4,
    this.raioInterno = 16,
    this.raioExterno = 28,
    this.velocidadeAngular = 4.0,
    this.duracao = 5.0,
  }) : super(
         nome: 'Vendaval de Folhas',
         descricao:
             'Dois anéis de espinhos giram em sentidos opostos ao redor do usuário.',
         cooldown: 6.5,
         custoEnergia: 12.0,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;

    _anel(user, dano, raioInterno, velocidadeAngular, 0.0);
    // Meio passo de defasagem no anel de fora: sem isso os dois nascem
    // alinhados e o primeiro cruzamento só acontece meia volta depois.
    _anel(user, dano, raioExterno, -velocidadeAngular, pi / porAnel);
  }

  void _anel(
    AbilityUser user,
    double dano,
    double raio,
    double velocidade,
    double defasagem,
  ) {
    for (int i = 0; i < porAnel; i++) {
      user.parent?.add(
        OrbitProjectile(
          owner: user,
          anguloAtual: (2 * pi / porAnel) * i + defasagem,
          raio: raio,
          velocidadeAngular: velocidade,
          dmg: dano,
          lifeTime: duracao,
          sprPath: 'projeteis/folha.png',
          cor1: Palette.verde,
          cor2: Palette.verdeEsc,
          tipo: user.creatureData.tipo,
        ),
      );
    }
  }
}
