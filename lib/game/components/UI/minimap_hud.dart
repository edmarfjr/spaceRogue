import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import '../map/dungeon_generator.dart';

class MinimapHud extends PositionComponent with HasGameRef {
  Map _mapData;
  final Vector2 Function() getCurrentLogicalRoom;

  Map get mapData => _mapData;

  // Ao trocar de fase, recalcula os limites uma vez (antes era por frame)
  set mapData(Map value) {
    _mapData = value;
    _recalculateBounds();
  }

  final double cellSize = 4.0;
  final double spacing = 1.0; 
  
  final Paint currentRoomPaint = Paint()..color = Palette.branco;
  final Paint visitedRoomPaint = Paint()..color = Palette.indigo;
  final Paint bossRoomPaint = Paint()..color = Palette.vermelho;
  final Paint itemRoomPaint = Paint()..color = Palette.amarelo;
  final Paint unvisitedPaint = Paint()..color = Palette.azulEsc; 

  final Paint backgroundPaint = Paint()..color = Palette.preto;
  final Paint borderPaint = Paint()
    ..color = Palette.branco
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint roomOutlinePaint = Paint()
    ..color = Palette.preto
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  // Armazenam os limites para não ter que recalcular dentro do render
  int _minX = 0;
  int _minY = 0;
  final double _padding = 8.0; // Espaço preto de borda (4px pra cada lado)

  MinimapHud({
    required Map mapData,
    required this.getCurrentLogicalRoom,
    required Vector2 position,
  })  : _mapData = mapData,
        super(
         position: position,
         anchor: Anchor.topRight,
         size: Vector2.zero(), // Começa zerado, a classe define isso sozinha agora!
       ) {
    _recalculateBounds();
  }

  void _recalculateBounds() {
    if (_mapData.isEmpty) return;

    // 1. Calcula os extremos do mapa
    int minX = 9999;
    int maxX = -9999;
    int minY = 9999;
    int maxY = -9999;

    for (var room in _mapData.values) {
      if (room.x < minX) minX = room.x;
      if (room.x > maxX) maxX = room.x;
      if (room.y < minY) minY = room.y;
      if (room.y > maxY) maxY = room.y;
    }

    _minX = minX;
    _minY = minY;

    // 2. Descobre quantos pixels exatos as salas ocupam
    double totalBlockSize = cellSize + spacing;
    double mapPixelWidth = (maxX - minX + 1) * totalBlockSize;
    double mapPixelHeight = (maxY - minY + 1) * totalBlockSize;

    // 3. ATUALIZA O TAMANHO DO MINIMAPA
    size = Vector2(mapPixelWidth + _padding, mapPixelHeight + _padding);
  }

  @override
  void render(Canvas canvas) {
    if (mapData.isEmpty) return; 

    Vector2 currentRoomCoords = getCurrentLogicalRoom();

    // CHECAGEM DE OCULTAÇÃO (SALA TRANCADA)
    for (var room in mapData.values) {
      if (room.x == currentRoomCoords.x && room.y == currentRoomCoords.y) {
        if (!room.isCleared && room.type != RoomType.start) {
          return; // Aborta e esconde o minimapa!
        }
        break; 
      }
    }

    // DESENHA O FUNDO COM O TAMANHO ATUALIZADO
    // Adicionei 0.5 no offset do Rect para a linha de 1px da borda não ser cortada
    Rect bgRect = Rect.fromLTWH(0.5, 0.5, width - 1, height - 1);
    canvas.drawRect(bgRect, backgroundPaint);
    canvas.drawRect(bgRect, borderPaint);

    // Agora o offset é apenas metade da margem (para centralizar as salas dentro da caixinha)
    double offset = _padding / 2;
    double totalBlockSize = cellSize + spacing;

    canvas.save();
    canvas.clipRect(bgRect);

    // DESENHA AS SALAS
    for (var room in mapData.values) {
      
      bool isCurrentRoom = room.x == currentRoomCoords.x && room.y == currentRoomCoords.y;
      
      bool isAdjacent = ((room.x - currentRoomCoords.x).abs() == 1 && room.y == currentRoomCoords.y) ||
                        ((room.y - currentRoomCoords.y).abs() == 1 && room.x == currentRoomCoords.x);

      if (!room.isVisited && !isCurrentRoom && !isAdjacent) {
        continue;
      }

      double drawX = offset + (room.x - _minX) * totalBlockSize;
      double drawY = offset + (room.y - _minY) * totalBlockSize;

      Paint roomPaint = unvisitedPaint; 

      if (room.x == currentRoomCoords.x && room.y == currentRoomCoords.y) {
        roomPaint = currentRoomPaint; 
      } else{
        if (room.type == RoomType.boss) {
          roomPaint = bossRoomPaint;
        } else if (room.type == RoomType.item) {
          roomPaint = itemRoomPaint;
        } else {
          roomPaint = visitedRoomPaint; 
        }
      }

      Rect roomRect = Rect.fromLTWH(drawX, drawY, cellSize, cellSize);
      
      canvas.drawRect(roomRect, roomPaint);
      canvas.drawRect(roomRect, roomOutlinePaint);

      // Reaproveita o mesmo Paint da sala (mesma cor, mesmo estilo)
      final Paint passagePaint = roomPaint;
      double passageThickness = 2.0;
      double centerOffset = (cellSize - passageThickness) / 2;

      // Desenha passagem para a DIREITA
      if (room.doorRight) {
        canvas.drawRect(
          Rect.fromLTWH(
            drawX + cellSize,          // Começa na borda direita da sala
            drawY + centerOffset,      // Centralizado no Y
            spacing,                   // Comprimento = espaço entre salas
            passageThickness           // Espessura da porta
          ), 
          passagePaint
        );
      }

      // Desenha passagem para BAIXO
      if (room.doorBottom) {
        canvas.drawRect(
          Rect.fromLTWH(
            drawX + centerOffset,      // Centralizado no X
            drawY + cellSize,          // Começa na borda inferior da sala
            passageThickness,          // Espessura da porta
            spacing                    // Comprimento = espaço entre salas
          ), 
          passagePaint
        );
      }
    }

    canvas.restore(); 
  }
}