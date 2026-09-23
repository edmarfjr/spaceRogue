import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Evolução de [Enraizar]: as raízes deixam de ser só casca dura e passam a
/// PRENDER quem está por perto.
///
/// A forma base é a única habilidade do jogo que não faz absolutamente nada
/// com o inimigo — troca movimento por redução de dano e espera passar. Isso
/// combina com um toco, mas deixa o botão B morto contra quem simplesmente
/// anda pra longe e atira.
///
/// Aqui o ato de cravar solta uma onda sem dano que paralisa no raio: o Toco
/// continua não machucando com esta habilidade (quem machuca é o anel de
/// folhas), mas agora ele escolhe QUEM fica parado junto com ele.
class EnraizarEvo extends Ability {
  final double reducaoDano;
  final double duracao;
  final double duracaoParalise;
  final double raio;

  const EnraizarEvo({
    this.reducaoDano = 1.0,
    this.duracao = 4.0,
    this.duracaoParalise = 1.5,
    this.raio = 40,
  }) : super(
         nome: 'Raízes Profundas',
         descricao:
             'Crava raízes: reduz o dano recebido e prende quem estiver perto.',
         cooldown: 7.0,
         tipo: AbilityTipo.defesa,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.damageReduction = reducaoDano;
    user.speedLocked = true;
    user.shieldVisualActive = true;

    // Dano ZERO de propósito: a onda é o agarrão das raízes, não um golpe.
    user.parent?.add(
      ExplosionHitbox(
        position: user.position.clone(),
        dmg: 0,
        knockback: 0,
        paraliseDuration: duracaoParalise,
        size: Vector2.all(raio),
        tipo: user.creatureData.tipo,
      ),
    );

    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted) {
        user.damageReduction = 0.0;
        user.speedLocked = false;
        // A forma base religa o visual aqui por engano (`= true` no fim do
        // `Future`), o que deixava a bolha acesa pra sempre depois do primeiro
        // uso. Aqui desliga, que é o que o resto do kit defensivo faz.
        user.shieldVisualActive = false;
      }
    });
  }
}
