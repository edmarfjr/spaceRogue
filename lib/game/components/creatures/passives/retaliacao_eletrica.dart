import '../../player/player.dart';
import '../../projeteis/explosion_hitbox.dart';
import '../passive.dart';

/// Ouriço Elétrico — antes era `EscudoDeEspinhos` (botão B), presa dentro do
/// `if (shieldHits > 0)` de `Player.takeDamage` — só existia enquanto a
/// bolha de habilidade estivesse ativa. Como passiva, sai da prisão: agora
/// dispara em TODO golpe que o treinador tenta tomar, escudo ativo ou não.
/// Mesmos números da habilidade original.
class RetaliacaoEletrica extends Passive {
  final double coef;
  final double stunDuration;
  const RetaliacaoEletrica({this.coef = 0.5, this.stunDuration = 1.0})
      : super(nome: 'Retaliação Elétrica', descricao: 'Todo golpe que o treinador tenta tomar dispara uma explosão elétrica ao redor dele, que atordoa.');

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(ExplosionHitbox(
      position: player.position.clone(),
      dmg: player.creatureData.stats.ataque * coef,
      isStun: true,
      stunDuration: stunDuration,
    ));
  }
}
