import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Cobra de Água — botão A. Rajada curta de tiros em sequência, feito um
/// jato de água martelando o alvo por um instante. Diferente do Jato d'Água
/// do Sapo (tiro único): aqui é uma sequência de tiros curtos disparados
/// automaticamente quando o botão é apertado.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class JatoAquatico extends Ability {
  final int tiros;
  final double intervalo;
  final double coef;
  final double velocidade;
  final double alcanceSegundos;

  const JatoAquatico({
    this.tiros = 5,
    this.intervalo = 0.08,
    this.coef = 0.25,
    this.velocidade = 200,
    this.alcanceSegundos = 0.25,
  }) : super(nome: "Jato d'Água", descricao: "Rajada curta de tiros em sequência.", cooldown: 2.5);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    final direction = dir.clone();

    for (int i = 0; i < tiros; i++) {
      Future.delayed(Duration(milliseconds: (i * intervalo * 1000).round()), () {
        if (!user.isMounted) return;
        user.parent?.add(Projectile(
          owner: user,
          position: user.position.clone(),
          direction: direction,
          speed: velocidade,
          dmg: dano,
          lifeTime: alcanceSegundos,
          sprPath: 'projeteis/proj1.png',
          cor1: Palette.azul,
          cor2: Palette.royal,
          tipo: user.creatureData.tipo,
        ));
      });
    }
  }
}
