import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import '../map/dungeon_generator.dart';

class MinimapHud extends PositionComponent with HasGameRef {
  Map mapData;
  final Vector2 Function() getCurrentLogicalRoom;

  final double cellSize = 4.0;
  final double spacing = 1.0; 
  
  final Paint currentRoomPaint = Paint()..color = Palette.branco;
  final Paint visitedRoomPaint = Paint()..color = Palette.cinza;
  final Paint bossRoomPaint = Paint()..color = Palette.vermelho;
  final Paint itemRoomPaint = Paint()..color = Palette.amarelo;

  final Paint backgroundPaint = Paint()..color = Palette.preto;
  final Paint borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
    

  final Paint roomOutlinePaint = Paint()
    ..color = Palette.preto
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  MinimapHud({
    required this.mapData,
    required this.getCurrentLogicalRoom,
    required Vector2 position, 
  }) : super(position: position);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final currentRoom = getCurrentLogicalRoom();

    final Paint connectionPaint = Paint()
      ..color = Palette.cinzaEsc
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;
    bool hasVisited = false;

    for (var room in mapData.values) {
      if (!room.isVisited) continue;
      hasVisited = true;

      double dx = (room.x - currentRoom.x) * (cellSize + spacing);
      double dy = (room.y - currentRoom.y) * (cellSize + spacing);

      if (dx < minX) minX = dx;
      if (dx > maxX) maxX = dx;
      if (dy < minY) minY = dy;
      if (dy > maxY) maxY = dy;
    }

    if (hasVisited) {
      double padding = 3.0; 
      
      Rect bgRect = Rect.fromLTRB(
        minX - (cellSize / 2) - padding,
        minY - (cellSize / 2) - padding,
        maxX + (cellSize / 2) + padding,
        maxY + (cellSize / 2) + padding,
      );
      
      canvas.drawRect(bgRect, backgroundPaint); 
      canvas.drawRect(bgRect, borderPaint);     
    }

    for (var room in mapData.values) {
      //if (!room.isVisited) continue;

      double dx = (room.x - currentRoom.x) * (cellSize + spacing);
      double dy = (room.y - currentRoom.y) * (cellSize + spacing);
      Offset center = Offset(dx, dy);

      if (room.doorTop) {
        var neighbor = mapData['${room.x},${room.y - 1}'];
        if (neighbor != null && neighbor.isVisited) {
          double neighborDy = (neighbor.y - currentRoom.y) * (cellSize + spacing);
          canvas.drawLine(center, Offset(dx, neighborDy), connectionPaint);
        }
      }
      if (room.doorBottom) {
        var neighbor = mapData['${room.x},${room.y + 1}'];
        if (neighbor != null && neighbor.isVisited) {
          double neighborDy = (neighbor.y - currentRoom.y) * (cellSize + spacing);
          canvas.drawLine(center, Offset(dx, neighborDy), connectionPaint);
        }
      }
      if (room.doorLeft) {
        var neighbor = mapData['${room.x - 1},${room.y}'];
        if (neighbor != null && neighbor.isVisited) {
          double neighborDx = (neighbor.x - currentRoom.x) * (cellSize + spacing);
          canvas.drawLine(center, Offset(neighborDx, dy), connectionPaint);
        }
      }
      if (room.doorRight) {
        var neighbor = mapData['${room.x + 1},${room.y}'];
        if (neighbor != null && neighbor.isVisited) {
          double neighborDx = (neighbor.x - currentRoom.x) * (cellSize + spacing);
          canvas.drawLine(center, Offset(neighborDx, dy), connectionPaint);
        }
      }
    }

    for (var room in mapData.values) {
      //if (!room.isVisited) continue; 

      double dx = (room.x - currentRoom.x) * (cellSize + spacing);
      double dy = (room.y - currentRoom.y) * (cellSize + spacing);

      Rect rect = Rect.fromLTWH(dx - (cellSize / 2), dy - (cellSize / 2), cellSize, cellSize);

      Paint paintToUse;
      if (room.x == currentRoom.x && room.y == currentRoom.y) {
        paintToUse = currentRoomPaint;
      } else if (room.type == RoomType.boss) {
        paintToUse = bossRoomPaint;
      } else if (room.type == RoomType.item) {
        paintToUse = itemRoomPaint;
      } else {
        paintToUse = visitedRoomPaint; 
      }

      canvas.drawRect(rect, paintToUse);
      canvas.drawRect(rect, roomOutlinePaint); 
    }
  }
}