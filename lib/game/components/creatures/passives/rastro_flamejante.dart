import 'package:flame/components.dart';
import '../../core/palette.dart';
import '../../player/player.dart';
import '../../projeteis/explosion_hitbox.dart';
import '../passive.dart';

/// Roedor de Fogo — antes era `DisparadaFlamejante` (botão B). Toda esquiva
/// do treinador deixa uma explosão de fogo no ponto de partida e outra no de
/// chegada — mesmo par de coeficientes da habilidade original, só que sem
/// botão, disparando sempre que a criatura estiver no grupo. Números
/// herdados, não tunados como passiva.
class RastroFlamejante extends Passive {
  final double coef;
  const RastroFlamejante({this.coef = 0.5})
      : super(
          nome: 'Rastro Flamejante',
          descricao: 'Toda esquiva do treinador incendeia o ponto de partida e o de chegada.',
        );

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    final dano = player.creatureData.stats.ataque * coef;
    player.parent?.add(ExplosionHitbox(
      position: player.position.clone(),
      dmg: dano,
      cor2: Palette.laranja,
    ));
    final duracao = player.dodgeIframeDuration;
    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (player.isMounted) {
        player.parent?.add(ExplosionHitbox(
          position: player.position.clone(),
          dmg: dano,
          cor2: Palette.laranja,
        ));
      }
    });
  }
}
