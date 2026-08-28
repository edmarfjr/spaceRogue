import 'package:flame/components.dart';
import '../../player/player.dart';
import '../../projeteis/explosion_hitbox.dart';
import '../passive.dart';

/// Leão Elétrico — antes era `InvestidaDaLanca` (botão B). A esquiva termina
/// em golpe no ponto de chegada, com empurrão — mesma ideia da habilidade
/// original (o pouso machuca, não o trajeto), coeficiente reduzido porque
/// agora dispara sempre, sem custo de botão.
class GolpeDeLanca extends Passive {
  final double coef;
  final double empurrao;
  const GolpeDeLanca({this.coef = 2.5, this.empurrao = 40})
      : super(nome: 'Golpe de Lança', descricao: 'A esquiva do treinador termina num golpe com empurrão no ponto de chegada.');

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    final dano = player.creatureData.stats.ataque * coef;
    final duracao = player.dodgeIframeDuration;
    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (player.isMounted) {
        player.parent?.add(ExplosionHitbox(
          position: player.position.clone(),
          dmg: dano,
          knockback: empurrao,
          size: Vector2(16, 16),
        ));
      }
    });
  }
}
