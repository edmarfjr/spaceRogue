import 'dart:math';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Ouriço Elétrico — botão A. Sem mira: uma saraivada de espinhos em todas as
/// direções ao mesmo tempo. É a única ofensiva dele — o resto do kit é
/// retaliação passiva (ver EscudoDeEspinhos).
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class Ericar extends Ability {
  final double coef;
  final int quantidade;
  final double velocidade;

  const Ericar({this.coef = 0.5, this.quantidade = 8, this.velocidade = 110})
      : super(nome: 'Eriçar', cooldown: 2.2);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    for (int i = 0; i < quantidade; i++) {
      final angulo = (2 * pi / quantidade) * i;
      final direcao = Vector2(cos(angulo), sin(angulo));
      user.parent?.add(Projectile(
        position: user.position.clone(),
        direction: direcao,
        speed: velocidade,
        dmg: dano,
        lifeTime: 0.5,
        sprPath: 'projeteis/raio.png',
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
        tipo: user.creatureData.tipo,
      ));
    }
  }
}
