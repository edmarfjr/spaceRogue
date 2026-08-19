import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/choque_eletrico.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/cuspe_venenoso.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/deixar_bomba.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/disparada_veloz.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esquiva_bomba.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/esquiva_tornado.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/explosao_venenosa.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/soco_flamejante.dart';
import 'abilities/bico_eletrico.dart';
import 'abilities/bolha_protetora.dart';
import 'abilities/brado.dart';
import 'abilities/casco_fechado.dart';
import 'abilities/corrente_estatica.dart';
import 'abilities/cuspe_de_semente.dart';
import 'abilities/disparada_flamejante.dart';
import 'abilities/jato_aquatico.dart';
import 'abilities/bola_dagua.dart';
import 'abilities/jogada_de_corpo.dart';
import 'abilities/mega_soco.dart';
import 'abilities/rajada_de_brasa.dart';
import 'base_stats.dart';
import 'creature_data.dart';
import 'creature_type.dart';
import '../effects/movement_animator.dart';
import '../enemies/creatures/ave_eletrica_enemy.dart';
import '../enemies/creatures/bomba_fogo_enemy.dart';
import '../enemies/creatures/cobra_agua_enemy.dart';
import '../enemies/creatures/grilo_eletrico_enemy.dart';
import '../enemies/creatures/roedor_fogo_enemy.dart';
import '../enemies/creatures/sapo_agua_enemy.dart';
import '../enemies/creatures/slime_planta_enemy.dart';
import '../enemies/creatures/tartaruga_planta_enemy.dart';
import '../enemies/creatures/tornado_fogo_enemy.dart';
import '../enemies/creatures/urso_planta_enemy.dart';

class CreatureRegistry {
  static final CreatureData roedorFogo = CreatureData(
    id: 'roedor_fogo',
    nome: 'Roedor de Fogo',
    spritePath: 'actors/ratFogo.png',
    tipo: CreatureType.fogo,
    corClara: Palette.laranja,
    corEscura: Palette.vermelho,
    stats: BaseStats(maxHp: 8, speed: 70, defesa: 1, ataque: 3),
    ability1: RajadaDeBrasa(),
    ability2: DisparadaFlamejante(),
    moveAnim: MovementAnimation.caminhada,
    hitboxSize: Vector2(8, 10), // ágil e frágil: corpo pequeno
    enemyBuilder: (pos, plr) => RoedorFogoEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData tartarugaPlanta = CreatureData(
    id: 'tartaruga_planta',
    nome: 'Tartaruga de Planta',
    spritePath: 'actors/tartPlanta.png',
    tipo: CreatureType.planta,
    corClara: Palette.verde,
    corEscura: Palette.verdeEsc,
    stats: BaseStats(maxHp: 20, speed: 35, defesa: 4, ataque: 3),
    ability1: CuspeDeSemente(),
    ability2: CascoFechado(),
    moveAnim: MovementAnimation.arrastar,
    hitboxSize: Vector2(14, 14), // resistente: corpo largo
    enemyBuilder: (pos, plr) => TartarugaPlantaEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData sapoAgua = CreatureData(
    id: 'sapo_agua',
    nome: 'Sapo de Água',
    spritePath: 'actors/sapoAgua.png',
    tipo: CreatureType.agua,
    corClara: Palette.azul,
    corEscura: Palette.indigo,
    stats: BaseStats(maxHp: 14, speed: 50, defesa: 2, ataque: 2),
    ability1: BolaDagua(),
    ability2: BolhaProtetora(),
    moveAnim: MovementAnimation.saltitar,
    hitboxSize: Vector2(12, 10), // balanceado: tamanho médio
    enemyBuilder: (pos, plr) => SapoAguaEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData aveEletrica = CreatureData(
    id: 'ave_eletrica',
    nome: 'Ave de Eletricidade',
    spritePath: 'actors/aveEletric.png',
    tipo: CreatureType.eletrico,
    corClara: Palette.amarelo,
    corEscura: Palette.laranja,
    stats: BaseStats(maxHp: 12, speed: 80, defesa: 3, ataque: 1),
    ability1: BicoEletrico(),
    ability2: CorrenteEstatica(),
    moveAnim: MovementAnimation.flutuar,
    hitboxSize: Vector2(9, 11), // leve e veloz: corpo estreito
    enemyBuilder: (pos, plr) => AveEletricaEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData cobraAgua = CreatureData(
    id: 'cobra_agua',
    nome: 'Cobra de Água',
    spritePath: 'actors/cobraAgua.png',
    tipo: CreatureType.agua,
    corClara: Palette.azul,
    corEscura: Palette.laranja,
    stats: BaseStats(maxHp: 15, speed: 48, defesa: 4, ataque: 4),
    ability1: JatoAquatico(),
    ability2: JogadaDeCorpo(),
    moveAnim: MovementAnimation.arrastar,
    hitboxSize: Vector2(9, 14), // longa e fina, corpo de cobra
    enemyBuilder: (pos, plr) => CobraAguaEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData ursoPlanta = CreatureData(
    id: 'urso_planta',
    nome: 'Urso de Planta',
    spritePath: 'actors/ursoPlanta.png',
    tipo: CreatureType.planta,
    corClara: Palette.bege,
    corEscura: Palette.forest,
    stats: BaseStats(maxHp: 22, speed: 22, defesa: 5, ataque: 4),
    ability1: MegaSoco(),
    ability2: Brado(),
    moveAnim: MovementAnimation.caminhada,
    hitboxSize: Vector2(15, 16), // o maior e mais pesado do grupo
    enemyBuilder: (pos, plr) => UrsoPlantaEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData griloEletrico = CreatureData(
    id: 'grilo_eletrico',
    nome: 'Grilo Eletrico',
    spritePath: 'actors/griloEletric.png',
    tipo: CreatureType.eletrico,
    corClara: Palette.laranja,
    corEscura: Palette.marromEsc,
    stats: BaseStats(maxHp: 6, speed: 80, defesa: 1, ataque: 4),
    ability1: ChoqueEletrico(),
    ability2: DisparadaVeloz(),
    moveAnim: MovementAnimation.saltitar,
    hitboxSize: Vector2(8, 10), // ágil e frágil: corpo pequeno
    enemyBuilder: (pos, plr) => GriloEletricoEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData tornadoFogo = CreatureData(
    id: 'tornado_fogo',
    nome: 'Tornado de Fogo',
    spritePath: 'actors/furacFogo.png',
    tipo: CreatureType.fogo,
    corClara: Palette.vermelho,
    corEscura: Palette.roxoEsc,
    stats: BaseStats(maxHp: 10, speed: 70, defesa: 1, ataque: 4),
    ability1: SocoFlamejante(),
    ability2: EsquivaTornado(),
    moveAnim: MovementAnimation.flutuar,
    hitboxSize: Vector2(8, 10), // ágil e frágil: corpo pequeno
    enemyBuilder: (pos, plr) => TornadoFogoEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData bombaFogo = CreatureData(
    id: 'bomba_fogo',
    nome: 'Bomba de Fogo',
    spritePath: 'actors/bombaFogo.png',
    tipo: CreatureType.fogo,
    corClara: Palette.picotronBege,
    corEscura: Palette.roxoEsc,
    stats: BaseStats(maxHp: 10, speed: 70, defesa: 3, ataque: 4),
    ability1: DeixarBomba(),
    ability2: EsquivaBomba(),
    moveAnim: MovementAnimation.saltitar,
    hitboxSize: Vector2(8, 10),
    enemyBuilder: (pos, plr) => BombaFogoEnemy(position: pos, playerTarget: plr),
  );

  static final CreatureData slimePlanta = CreatureData(
    id: 'slime_planta',
    nome: 'Slime de Planta',
    spritePath: 'actors/slimePlanta.png',
    tipo: CreatureType.planta,
    corClara: Palette.verde,
    corEscura: Palette.verdeEsc,
    stats: BaseStats(maxHp: 10, speed: 70, defesa: 3, ataque: 4),
    ability1: CuspeVenenoso(),
    ability2: ExplosaoVenenosa(),
    moveAnim: MovementAnimation.arrastar,
    hitboxSize: Vector2(8, 10),
    enemyBuilder: (pos, plr) => SlimePlantaEnemy(position: pos, playerTarget: plr),
  );

  static final List<CreatureData> all = [
    roedorFogo,
    tartarugaPlanta,
    sapoAgua,
    aveEletrica,
    tornadoFogo,
    cobraAgua,
    ursoPlanta,
    griloEletrico,
    bombaFogo,
    slimePlanta
  ];

  static CreatureData byId(String id) => all.firstWhere((c) => c.id == id);
}
