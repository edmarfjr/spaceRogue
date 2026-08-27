import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Caranguejo Ermitão de Fogo — botão A. Baforada curta de cinzas quentes:
/// alcance baixo, mas a cinza gruda e continua queimando depois do sopro.
///
/// Metade "dano" do kit: cinza queima, fumaça controla (ver RecolherNoCasco).
/// A queimadura é estouro — entrega quase tudo em menos de um segundo e não
/// acumula, então insistir no mesmo alvo não rende mais que acertar uma vez.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class BaforadaDeCinzas extends Ability {
  final double coef;
  final double velocidade;
  final double alcanceSegundos;
  final int ticksQueimadura;

  const BaforadaDeCinzas({
    this.coef = 0.6,
    this.velocidade = 70,
    this.alcanceSegundos = 0.35,
    this.ticksQueimadura = 2,
  }) : super(nome: 'Baforada de Cinzas', descricao: 'Baforada curta de cinzas quentes que grudam e continuam queimando.', cooldown: 1.6);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      lifeTime: alcanceSegundos,
      sprPath: 'projeteis/nuvemP.png',
      cor1: user.creatureData.corClara,
      cor2: user.creatureData.corEscura,
      tipo: user.creatureData.tipo,
      dotKind: DotKind.queimadura,
      dotTicks: ticksQueimadura,
      radius: 9,
    ));
  }
}
