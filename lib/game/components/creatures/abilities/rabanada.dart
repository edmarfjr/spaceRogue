import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Peixe Neutro — botão A. Golpe de cauda em área curta, sem elemento — a
/// piada é que parece ataque de água mas não é.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class Rabanada extends Ability {
  final double coef;
  final double velocidade;

  const Rabanada({this.coef = 1.5, this.velocidade = 160})
    : super(
        nome: 'Rabanada',
        descricao: 'Golpe de cauda em área curta.',
        cooldown: 0.9,
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
        lifeTime: 0.5,
        dmg: dano,
        radius: 8,
        sprPath: 'projeteis/proj1.png',
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
        tipo: user.creatureData.tipo,
      ),
    );
  }
}
