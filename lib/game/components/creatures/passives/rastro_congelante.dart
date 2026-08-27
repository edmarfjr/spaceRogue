import 'package:flame/components.dart';
import '../../core/palette.dart';
import '../../player/player.dart';
import '../../projeteis/explosion_hitbox.dart';
import '../passive.dart';

/// Pinguim de Água — antes era `DisparadaCongelante` (botão B). A esquiva do
/// treinador deixa uma explosão gelada no ponto de partida e outra na
/// chegada, e as duas aplicam lentidão em quem acertarem — mesmos
/// coeficientes da habilidade original.
class RastroCongelante extends Passive {
  final double coef;
  final double lentidaoDuracao;
  const RastroCongelante({this.coef = 0.5, this.lentidaoDuracao = 3.0})
      : super(nome: 'Rastro Congelante', descricao: 'Toda esquiva do treinador congela o ponto de partida e o de chegada, deixando quem passar por ali mais lento.');

  void _explodir(Player player) {
    player.parent?.add(ExplosionHitbox(
      position: player.position.clone(),
      dmg: player.creatureData.stats.ataque * coef,
      cor1: Palette.royal,
      cor2: Palette.azul,
      lentidaoDuracao: lentidaoDuracao,
    ));
  }

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    _explodir(player);
    final duracao = player.dodgeIframeDuration;
    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (player.isMounted) _explodir(player);
    });
  }
}
