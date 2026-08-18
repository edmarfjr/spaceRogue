import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/creatures/ability.dart';
import 'package:spacerogue/game/components/player/player.dart';
import 'package:spacerogue/game/components/projeteis/projectile.dart';

/// Sapo de Água — botão A. Projétil reto e rápido, sem truque: é a linha
/// de base contra a qual as outras habilidades ofensivas são comparadas.
class JatoDagua extends Ability {
  final double dano;
  final double velocidade;

  const JatoDagua({this.dano = 3, this.velocidade = 220})
      : super(nome: "Jato d'Água", cooldown: 0.6);

  @override
  void execute(Player user, Vector2 dir) {
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/proj1.png',
      cor1: Palette.azul,
      cor2: Palette.azulEsc,
    ));
  }
}
