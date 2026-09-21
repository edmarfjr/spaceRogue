import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Evolução de `CuspeVenenoso`: o cuspe SE DIVIDE ao morrer, espalhando duas
/// gotas em direções aleatórias.
///
/// Usa o `fragmentos` que o `Projectile` já tinha (ver `Projectile.onDestroy`)
/// — os filhos herdam dano, veneno e sprite do pai, então a divisão não
/// precisa de código novo aqui.
///
/// A divisão acontece tanto ao acertar quanto ao expirar, o que casa com o
/// tema: o veneno do Slime não some, ele se espalha.
class CuspeVenenosoEvo extends Ability {
  final double coef;
  final double velocidade;
  final int fragmentos;
  final int dotTicks;

  const CuspeVenenosoEvo({
    this.coef = 1.1,
    this.velocidade = 105,
    this.fragmentos = 2,
    this.dotTicks = 5,
  }) : super(
         nome: 'Cuspe Venenoso+',
         descricao: 'Cuspe que se divide em duas gotas e envenena mais.',
         cooldown: 0.4,
         custoEnergia: 4.0,
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
        sprPath: 'projeteis/proj1.png',
        cor1: Palette.verde,
        cor2: Palette.verdeEsc,
        tipo: user.creatureData.tipo,
        dotKind: DotKind.veneno,
        dotTicks: dotTicks,
        fragmentos: fragmentos,
        // Vida menor que o padrão (10s): o `fragmentos` também dispara quando
        // o projétil EXPIRA, e com vida longa o tiro que erra tudo ainda
        // encheria a sala de gotas segundos depois.
        lifeTime: 2.0,
      ),
    );
  }
}
