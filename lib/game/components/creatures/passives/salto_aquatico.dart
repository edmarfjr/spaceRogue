import 'package:flame/components.dart';
import '../../core/palette.dart';
import '../../player/player.dart';
import '../../projeteis/explosion_hitbox.dart';
import '../passive.dart';

/// Cobra de Água — antes era `JogadaDeCorpo` (botão B). Único caso do
/// conjunto que não vira i-frame + rastro: a habilidade original é um pulo
/// de verdade (`startJump`), que só `Companion` executa de verdade — `Player`
/// não tem curva de salto própria. Em vez de reescrever `Player.dodge()` pra
/// pular, o efeito fica só aditivo: uma explosão d'água no ponto de chegada
/// do dash, no mesmo instante em que uma aterrissagem aconteceria.
class SaltoAquatico extends Passive {
  final double coef;
  const SaltoAquatico({this.coef = 0.4})
      : super(
          nome: 'Salto Aquático',
          descricao: 'A esquiva do treinador termina num respingo d\'água no ponto de chegada.',
        );

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    final dano = player.creatureData.stats.ataque * coef;
    final duracao = player.dodgeIframeDuration;
    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (player.isMounted) {
        player.parent?.add(ExplosionHitbox(
          position: player.position.clone(),
          dmg: dano,
          knockback: 30,
          size: Vector2(28, 28),
          cor1: Palette.azul,
          cor2: Palette.royal,
        ));
      }
    });
  }
}
