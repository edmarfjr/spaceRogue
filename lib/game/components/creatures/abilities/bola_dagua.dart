import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Sapo de Água — botão A. Projétil reto e rápido, sem truque: é a linha
/// de base contra a qual as outras habilidades ofensivas são comparadas.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class BolaDagua extends Ability {
  final double coef;
  final double velocidade;

  const BolaDagua({this.coef = 1.5, this.velocidade = 220})
      : super(nome: "Bola d'Água", cooldown: 0.6);

  @override
  void execute(Player user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    user.parent?.add(Projectile(
      position: user.position.clone(),
      direction: dir,
      speed: velocidade,
      dmg: dano,
      sprPath: 'projeteis/proj1.png',
      cor1: Palette.azul,
      cor2: Palette.azulEsc,
      tipo: user.creatureData.tipo,
    ));
  }
}
