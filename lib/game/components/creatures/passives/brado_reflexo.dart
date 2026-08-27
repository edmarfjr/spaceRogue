import 'package:flame/components.dart';
import '../../player/player.dart';
import '../../projeteis/explosion_hitbox.dart';
import '../passive.dart';

/// Urso de Planta — antes era `Brado` (botão B). Todo golpe que o treinador
/// tenta tomar empurra tudo ao redor pra longe, sem atordoar — mesmos
/// números da habilidade original. É o "sai de perto" automático do
/// conjunto de retaliações.
class BradoReflexo extends Passive {
  final double coef;
  final double empurrao;
  const BradoReflexo({this.coef = 0.25, this.empurrao = 100})
      : super(nome: 'Brado Reflexo', descricao: 'Todo golpe que o treinador tenta tomar empurra tudo ao redor dele pra longe.');

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(ExplosionHitbox(
      position: player.position.clone(),
      dmg: player.creatureData.stats.ataque * coef,
      knockback: empurrao,
      size: Vector2(48, 48),
    ));
  }
}
