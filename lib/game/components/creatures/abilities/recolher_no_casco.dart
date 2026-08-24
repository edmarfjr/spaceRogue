import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Caranguejo Ermitão de Fogo — botão B. Recolhe no casco: reduz dano recebido
/// em troca de ficar parado, e o ato de recolher despeja uma nuvem de fumaça
/// que fica no chão.
///
/// Metade "controle" do kit — a fumaça não dá dano nenhum, ela **cega e
/// atrasa**: inimigo dentro dela perde o rastro do jogador (quem persegue
/// passa a vagar, quem atira para de mirar) e anda na metade da velocidade.
/// Quem machuca é a cinza (ver BaforadaDeCinzas); somar dano aqui apagaria a
/// diferença entre as duas.
class RecolherNoCasco extends Ability {
  final double reducaoDano;
  final double duracao;
  final double duracaoCegueira;
  final double duracaoLentidao;

  const RecolherNoCasco({
    this.reducaoDano = 0.8,
    this.duracao = 2.5,
    this.duracaoCegueira = 2.5,
    this.duracaoLentidao = 3.0,
  }) : super(nome: 'Recolher no Casco', cooldown: 6.5, tipo: AbilityTipo.defesa);

  @override
  void execute(Player user, Vector2 dir) {
    user.damageReduction = reducaoDano;
    user.speedLocked = true;
    user.shieldVisualActive = true;

    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: Vector2.zero(),
      speed: 0,
      dmg: 0,
      kbForce: 0,
      sprPath: 'projeteis/nuvem.png',
      cor1: user.creatureData.corClara,
      cor2: user.creatureData.corEscura,
      cegoDuracao: duracaoCegueira,
      lentidaoDuracao: duracaoLentidao,
      atravessa: 10,
      size: Vector2(24, 24),
      lifeTime: duracao,
      radius: 12,
    ));

    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted) {
        user.damageReduction = 0.0;
        user.speedLocked = false;
        user.shieldVisualActive = false;
      }
    });
  }
}
