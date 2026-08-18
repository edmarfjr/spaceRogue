import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'abilities/bico_eletrico.dart';
import 'abilities/bolha_protetora.dart';
import 'abilities/brado.dart';
import 'abilities/casco_fechado.dart';
import 'abilities/corrente_estatica.dart';
import 'abilities/cuspe_de_semente.dart';
import 'abilities/disparada_flamejante.dart';
import 'abilities/jato_aquatico.dart';
import 'abilities/jato_dagua.dart';
import 'abilities/jogada_de_corpo.dart';
import 'abilities/mega_soco.dart';
import 'abilities/rajada_de_brasa.dart';
import 'base_stats.dart';
import 'creature_data.dart';
import 'creature_type.dart';
import '../effects/movement_animator.dart';
import '../enemies/creatures/ave_eletrica_enemy.dart';
import '../enemies/creatures/cobra_agua_enemy.dart';
import '../enemies/creatures/roedor_fogo_enemy.dart';
import '../enemies/creatures/sapo_agua_enemy.dart';
import '../enemies/creatures/tartaruga_planta_enemy.dart';
import '../enemies/creatures/urso_planta_enemy.dart';

class CreatureRegistry {
  static final CreatureData roedorFogo = CreatureData(
    id: 'roedor_fogo',
    nome: 'Roedor de Fogo',
    spritePath: 'actors/ratFogo.png',
    tipo: CreatureType.fogo,
    corClara: Palette.vermelho,
    corEscura: Palette.laranja,
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
    ability1: JatoDagua(),
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

  static final List<CreatureData> all = [
    roedorFogo,
    tartarugaPlanta,
    sapoAgua,
    aveEletrica,
    cobraAgua,
    ursoPlanta,
  ];

  static CreatureData byId(String id) => all.firstWhere((c) => c.id == id);
}
