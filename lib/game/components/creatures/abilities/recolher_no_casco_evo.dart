import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [RecolherNoCasco]: mesma fumaça que cega e atrasa, mas agora o
/// casco também DEVOLVE os tiros.
///
/// A forma base trocava movimento por sobrevivência e nada mais — ficar
/// parado era puro tempo perdido. Com a reflexão (`refleteProjetil`, o mesmo
/// campo que o Casco Fechado da Tartaruga usa), o tempo recolhido vira ofensa
/// contra quem atira, sem ganhar dano de área nenhum: a divisão do kit
/// continua valendo, quem machuca de perto é a cinza.
///
/// A nuvem também dura mais e nasce maior, porque o Caranguejo evoluído passa
/// mais tempo dentro dela.
class RecolherNoCascoEvo extends Ability {
  final double reducaoDano;
  final double duracao;
  final double duracaoCegueira;
  final double duracaoLentidao;

  const RecolherNoCascoEvo({
    this.reducaoDano = 1,
    this.duracao = 3.0,
    this.duracaoCegueira = 3.5,
    this.duracaoLentidao = 4.0,
  }) : super(
         nome: 'Casco de Brasa',
         descricao:
             'Recolhe reduzindo dano e refletindo tiros, dentro de uma fumaça que cega e atrasa.',
         cooldown: 6.5,
         tipo: AbilityTipo.defesa,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.damageReduction = reducaoDano;
    user.speedLocked = true;
    user.shieldVisualActive = true;
    user.refleteProjetil = true;

    user.parent?.add(
      Projectile(
        owner: user,
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
        size: Vector2(32, 32),
        lifeTime: duracao,
        radius: 16,
      ),
    );

    // Mesmo `Future.delayed` da forma base — inclusive o desligamento da
    // reflexão, que precisa acontecer no mesmo instante que o resto, senão o
    // Caranguejo sairia do casco ainda devolvendo tiro.
    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted) {
        user.damageReduction = 0.0;
        user.speedLocked = false;
        user.shieldVisualActive = false;
        user.refleteProjetil = false;
      }
    });
  }
}
