import 'dart:math';

enum RoomType { start, normal, boss, item }

class RoomData {
  final int x;
  final int y;
  RoomType type;
  
  bool doorTop = false;
  bool doorBottom = false;
  bool doorLeft = false;
  bool doorRight = false;
  bool isCleared = false;
  bool isVisited = false;

  RoomData(this.x, this.y, {this.type = RoomType.normal});
  
  int get doorCount => (doorTop ? 1 : 0) + (doorBottom ? 1 : 0) + (doorLeft ? 1 : 0) + (doorRight ? 1 : 0);
}

class DungeonGenerator {
  final int maxRooms;
  final Random _random = Random();
  
  DungeonGenerator({this.maxRooms = 15});

  Map<String, RoomData> generate() {
    Map<String, RoomData> grid = {};
    List<RoomData> roomQueue = [];

    var startRoom = RoomData(50, 50, type: RoomType.start);
    startRoom.isCleared = true;
    startRoom.isVisited = true;
    grid['50,50'] = startRoom;
    roomQueue.add(startRoom);

    int roomCount = 1;

    while (roomQueue.isNotEmpty && roomCount < maxRooms) {
      RoomData current = roomQueue.removeAt(0);
      
      List<List<int>> directions = [[0, -1], [0, 1], [-1, 0], [1, 0]];
      directions.shuffle(_random); // 

      for (var dir in directions) {
        if (roomCount >= maxRooms) break;
        
        if (_random.nextDouble() > 0.5) {
          int nx = current.x + dir[0];
          int ny = current.y + dir[1];
          String key = '$nx,$ny';

          if (!grid.containsKey(key)) {
            var newRoom = RoomData(nx, ny);
            
            if (dir[0] == 0 && dir[1] == -1) { 
              current.doorTop = true; newRoom.doorBottom = true; 
            } else if (dir[0] == 0 && dir[1] == 1) { 
              current.doorBottom = true; newRoom.doorTop = true; 
            } else if (dir[0] == -1 && dir[1] == 0) { 
              current.doorLeft = true; newRoom.doorRight = true; 
            } else if (dir[0] == 1 && dir[1] == 0) { 
              current.doorRight = true; newRoom.doorLeft = true; 
            }

            grid[key] = newRoom;
            roomQueue.add(newRoom);
            roomCount++;
          }
        }
      }
    }
    
    _assignSpecialRooms(grid);

    return grid;
  }
  
  void _assignSpecialRooms(Map<String, RoomData> grid) {
    List<RoomData> deadEnds = grid.values.where((r) => r.doorCount == 1 && r.type != RoomType.start).toList();
    
    if (deadEnds.isNotEmpty) {
      var bossRoom = deadEnds.removeLast();
      bossRoom.type = RoomType.boss;
      
      if (deadEnds.isNotEmpty) {
        var itemRoom = deadEnds.removeLast();
        itemRoom.type = RoomType.item;
      }
    }
  }
}