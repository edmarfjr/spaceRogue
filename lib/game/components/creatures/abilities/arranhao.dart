import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Gato Neutro — botão A. Golpe rápido de curto alcance, cadência altíssima
/// — o DPS vem do volume, não do golpe individual (mesma lógica do Bico
/// Elétrico, aqui reflavorado corpo a corpo).
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class Arranhao extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  const Arranhao({
    this.coef = 0.9,
    this.velocidade = 240,
    this.alcanceSegundos = 0.15,
  }) : super(
         nome: 'Arranhão',
         descricao: 'Golpe rápido de curto alcance, cadência altíssima.',
         cooldown: 0.35,
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
        dmg: dano,
        lifeTime: alcanceSegundos,
        sprPath: 'projeteis/proj2.png',
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
