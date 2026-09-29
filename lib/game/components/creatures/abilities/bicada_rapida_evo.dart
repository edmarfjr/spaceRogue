import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de [BicadaRapida]: a bicada agora ATRAVESSA.
///
/// Perfurar, e não abrir em leque, de propósito. Duas evoluções do elenco já
/// viraram leque (Tridente Relâmpago, Nuvem Errante) e uma terceira apagaria
/// o que diferencia o Paassarin: ele é a única criatura jogável que voa por
/// cima de pedra E de buraco, ou seja, a que atravessa o cenário em linha
/// reta. A bicada passa a atravessar o INIMIGO pelo mesmo motivo.
///
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class BicadaRapidaEvo extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;
  final double kbForce;
  final int atravessa;

  const BicadaRapidaEvo({
    this.coef = 1.1,
    this.velocidade = 300,
    this.alcanceSegundos = 0.3,
    this.kbForce = 5,
    this.atravessa = 2,
  }) : super(
         nome: 'Bicada Perfurante',
         descricao: 'Cadência altíssima, e cada bicada atravessa dois alvos.',
         // Cooldown baixo porque quem regula a cadência é o `custoEnergia` —
         // regra do elenco inteiro, ver `RajadaDeBrasa` e companhia.
         cooldown: 0.15,
         custoEnergia: 1.2,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(
      Projectile(
        owner: user,
        position: user.position.clone(),
        direction: dir,
        speed: velocidade,
        kbForce: kbForce,
        dmg: dano,
        atravessa: atravessa,
        sprPath: 'projeteis/proj2.png',
        lifeTime: alcanceSegundos,
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
