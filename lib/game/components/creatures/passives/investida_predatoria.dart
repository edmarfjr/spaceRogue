import 'dart:ui';
import 'package:flame/components.dart';
import '../../enemies/enemy.dart';
import '../../player/player.dart';
import '../passive.dart';

/// Tubarão de Água — antes era `Mordida`/`MergulhoEEstouro`. Único caso do
/// conjunto de esquiva que troca a DIREÇÃO do dash em vez de só somar um
/// efeito: em vez de afastar do perigo, a esquiva do treinador puxa pro
/// hostil mais próximo — fecha distância em vez de fugir, mesmo espírito do
/// Mergulho e Estouro original. Sem hostil na sala, cai pra direção padrão
/// (retorna null).
class InvestidaPredatoria extends Passive {
  const InvestidaPredatoria() : super(nome: 'Investida Predatória', descricao: 'A esquiva do treinador puxa pro hostil mais próximo em vez de afastar dele.');

  @override
  Vector2? direcaoEsquivaOverride(Player player, Vector2 direcaoPadrao) {
    final room = player.currentRoom;
    final inimigos = player.parent?.children.whereType<Enemy>() ?? const <Enemy>[];

    Enemy? maisProximo;
    double menorDistSq = double.infinity;
    for (final inimigo in inimigos) {
      if (room != null &&
          !room.toAbsoluteRect().contains(
              Offset(inimigo.absolutePosition.x, inimigo.absolutePosition.y))) {
        continue;
      }
      final distSq = (inimigo.absolutePosition - player.absolutePosition).length2;
      if (distSq < menorDistSq) {
        menorDistSq = distSq;
        maisProximo = inimigo;
      }
    }
    if (maisProximo == null) return null;

    final delta = maisProximo.absolutePosition - player.absolutePosition;
    if (delta.length == 0) return null;
    return delta.normalized();
  }
}
