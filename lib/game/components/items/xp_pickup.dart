import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'collectible.dart';
import '../player/player.dart';

/// Orbe de XP: 1 ponto de experiência de evolução pra criatura ativa (ver
/// `Player.ganharXp`). Substituiu o XP fixo por golpe que `Enemy.death()`
/// dava direto — agora é isto que os inimigos (e, com chance, obstáculos
/// destrutíveis) derrubam, e o jogador precisa coletar.
///
/// Sprite 8x8 (menor que o 16x16 padrão dos outros itens — ver
/// `Collectible.size`), pra caber vários espalhados sem dominar a tela
/// quando um boss derruba 10 de uma vez.
class XpPickup extends Collectible {
  /// Dentro desse raio (do jogador), o orbe voa até ele em vez de esperar o
  /// jogador andar por cima — só o de XP, os outros itens continuam parados.
  static const double _distanciaIma = 32.0;
  static const double _velocidadeIma = 60.0;

  XpPickup({required super.position})
    : super(
        spritePath: 'items/xp.png',
        cor1: Palette.azul,
        cor2: Palette.royal,
        size: Vector2(8, 8),
      );

  @override
  void update(double dt) {
    super.update(dt);

    final direcao = game.player.position - position;
    final distancia = direcao.length;
    if (distancia > _distanciaIma || distancia == 0) return;

    final passo = _velocidadeIma * dt;
    if (passo >= distancia) {
      position.setFrom(game.player.position);
    } else {
      position.add(direcao..scaleTo(passo));
    }
  }

  @override
  bool onCollect(Player player) {
    player.ganharXp(1);
    return true; // XP sempre entra: não tem limite de slot nem teto útil.
  }
}
