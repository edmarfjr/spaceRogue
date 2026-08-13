import 'dart:math';

enum RoomType { start, normal, boss, item }

class RoomData {
  final int x;
  final int y;
  RoomType type;
  
  // Controle de quais paredes possuem portas abertas
  bool doorTop = false;
  bool doorBottom = false;
  bool doorLeft = false;
  bool doorRight = false;
  bool isCleared = false;
  bool isVisited = false;

  RoomData(this.x, this.y, {this.type = RoomType.normal});
  
  // Retorna quantas portas esta sala possui
  int get doorCount => (doorTop ? 1 : 0) + (doorBottom ? 1 : 0) + (doorLeft ? 1 : 0) + (doorRight ? 1 : 0);
}

class DungeonGenerator {
  final int maxRooms;
  final Random _random = Random();
  
  DungeonGenerator({this.maxRooms = 15});

  // Retorna um Map onde a chave é a coordenada "x,y" e o valor são os dados da sala
  Map<String, RoomData> generate() {
    Map<String, RoomData> grid = {};
    List<RoomData> roomQueue = [];

    // 1. Sala inicial no centro do grid abstrato
    var startRoom = RoomData(50, 50, type: RoomType.start);
    startRoom.isCleared = true;
    startRoom.isVisited = true;
    grid['50,50'] = startRoom;
    roomQueue.add(startRoom);

    int roomCount = 1;

    // 2. Loop de Expansão
    while (roomQueue.isNotEmpty && roomCount < maxRooms) {
      // Pega a primeira sala da fila
      RoomData current = roomQueue.removeAt(0);
      
      // Lista de vetores de direção [X, Y]
      List<List<int>> directions = [[0, -1], [0, 1], [-1, 0], [1, 0]]; // Cima, Baixo, Esquerda, Direita
      directions.shuffle(_random); // Embaralha para não gerar a dungeon sempre para o mesmo lado

      for (var dir in directions) {
        if (roomCount >= maxRooms) break;
        
        // 50% de chance de tentar criar uma sala nesta direção
        if (_random.nextDouble() > 0.5) {
          int nx = current.x + dir[0];
          int ny = current.y + dir[1];
          String key = '$nx,$ny';

          // Verifica se a célula vizinha já está ocupada
          if (!grid.containsKey(key)) {
            var newRoom = RoomData(nx, ny);
            
            // CONECTANDO AS PORTAS
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
    
    // 3. (Opcional) Classificar as salas finais (Boss/Item)
    _assignSpecialRooms(grid);

    return grid;
  }
  
  void _assignSpecialRooms(Map<String, RoomData> grid) {
    // Filtra as salas que têm apenas 1 porta (são becos sem saída) e não são a sala inicial
    List<RoomData> deadEnds = grid.values.where((r) => r.doorCount == 1 && r.type != RoomType.start).toList();
    
    if (deadEnds.isNotEmpty) {
      // Para o Boss, idealmente pegamos a mais distante do centro, mas para simplificar aqui, pegaremos a última da lista
      var bossRoom = deadEnds.removeLast();
      bossRoom.type = RoomType.boss;
      
      if (deadEnds.isNotEmpty) {
        var itemRoom = deadEnds.removeLast();
        itemRoom.type = RoomType.item;
      }
    }
  }
}