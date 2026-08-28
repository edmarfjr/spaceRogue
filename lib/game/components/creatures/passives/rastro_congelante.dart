import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
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
      : super(nome: 'Rastro Congelante', descricao: 'Toda esquiva do treinador congela o ponto de partida, deixando quem passar por ali mais lento.');

  void _explodir(Player player) {
    player.parent?.add(ExplosionHitbox(
      position: player.position.clone(),
      dmg: player.creatureData.stats.ataque * coef,
      cor1: Palette.royal,
      cor2: Palette.azul,
      lentidaoDuracao: lentidaoDuracao,
    ));

    player.parent?.add(Projectile(
      position: player.position.clone(),
      direction: Vector2.zero(),
      speed: 0,
      dmg: 0,
      kbForce: 0,
      sprPath: 'projeteis/bolaGrande.png',
      cor1: Palette.royal,
      cor2: Palette.azul,
      lentidaoDuracao: lentidaoDuracao,
      atravessa: 10,
      size: Vector2(24, 24),
      lifeTime: 1.5,
      radius: 12,
    ));
  }

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    _explodir(player);
    //final duracao = player.dodgeIframeDuration;
    //Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
    //  if (player.isMounted) _explodir(player);
    //});
  }
}
