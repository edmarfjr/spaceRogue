import 'dart:math';

enum RoomType { start, normal, boss, item, shop }

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

  /// Marcada pelo item MAPA: aparece no minimapa sem o jogador ter entrado.
  /// Campo separado de [isVisited] de propósito — `isVisited` decide se a sala
  /// tranca ao entrar e se as portas nascem abertas, então reaproveitá-lo pra
  /// revelar faria o mapa "limpar" a dungeon inteira.
  bool isRevealed = false;

  RoomData(this.x, this.y, {this.type = RoomType.normal});
  
  int get doorCount => (doorTop ? 1 : 0) + (doorBottom ? 1 : 0) + (doorLeft ? 1 : 0) + (doorRight ? 1 : 0);
}

class DungeonGenerator {
  final int maxRooms;
  final Random _random = Random();

  static const List<List<int>> _direcoes = [[0, -1], [0, 1], [-1, 0], [1, 0]];

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

    while (roomCount < maxRooms) {
      if (roomQueue.isEmpty) {
        // A expansão é probabilística (50% por direção), então a fila pode
        // secar muito antes de `maxRooms`. No pior caso a própria sala inicial
        // sorteia "não" nas quatro direções (6,25% das vezes) e o andar nasce
        // com uma sala só — sem beco sem-saída, ou seja, sem boss e sem saída
        // do andar. Quando a fila seca, forçamos uma sala nova a partir de
        // qualquer sala que ainda tenha vizinho livre, até bater `maxRooms`.
        final expansiveis = grid.values
            .where((r) => _direcoesLivres(grid, r).isNotEmpty)
            .toList();
        if (expansiveis.isEmpty) break;

        final origem = expansiveis[_random.nextInt(expansiveis.length)];
        final livres = _direcoesLivres(grid, origem);
        roomQueue.add(
            _criarSala(grid, origem, livres[_random.nextInt(livres.length)]));
        roomCount++;
        continue;
      }

      RoomData current = roomQueue.removeAt(0);
      
      final directions = List<List<int>>.from(_direcoes)..shuffle(_random);

      for (var dir in directions) {
        if (roomCount >= maxRooms) break;
        
        if (_random.nextDouble() > 0.5) {
          if (grid.containsKey('${current.x + dir[0]},${current.y + dir[1]}')) {
            continue;
          }
          roomQueue.add(_criarSala(grid, current, dir));
          roomCount++;
        }
      }
    }
    
    _assignSpecialRooms(grid);

    return grid;
  }

  /// Direções a partir de [room] cuja célula vizinha ainda está vazia.
  List<List<int>> _direcoesLivres(Map<String, RoomData> grid, RoomData room) =>
      _direcoes
          .where((d) => !grid.containsKey('${room.x + d[0]},${room.y + d[1]}'))
          .toList();

  /// Cria a sala vizinha de [origem] na direção [dir], já ligando as portas dos
  /// dois lados, e registra ela no grid.
  RoomData _criarSala(
      Map<String, RoomData> grid, RoomData origem, List<int> dir) {
    final nova = RoomData(origem.x + dir[0], origem.y + dir[1]);

    if (dir[0] == 0 && dir[1] == -1) {
      origem.doorTop = true; nova.doorBottom = true;
    } else if (dir[0] == 0 && dir[1] == 1) {
      origem.doorBottom = true; nova.doorTop = true;
    } else if (dir[0] == -1 && dir[1] == 0) {
      origem.doorLeft = true; nova.doorRight = true;
    } else {
      origem.doorRight = true; nova.doorLeft = true;
    }

    grid['${nova.x},${nova.y}'] = nova;
    return nova;
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

      // Loja: beco sem-saída, se ainda sobrou algum. Senão, qualquer sala
      // comum serve — um andar sem loja deixaria as moedas juntadas nele sem
      // onde ser gastas, e o boss e o tesouro já consumiram os becos.
      RoomData? shopRoom;
      if (deadEnds.isNotEmpty) {
        shopRoom = deadEnds.removeLast();
      } else {
        final comuns =
            grid.values.where((r) => r.type == RoomType.normal).toList();
        if (comuns.isNotEmpty) shopRoom = comuns.last;
      }

      if (shopRoom != null) {
        shopRoom.type = RoomType.shop;
        // Loja já nasce limpa, como a sala inicial: sem isso ela trancaria e
        // geraria inimigos ao entrar, e o jogador brigaria dentro da loja. É
        // também o que faz as portas dela nascerem abertas.
        shopRoom.isCleared = true;
      }
    }
  }
}
