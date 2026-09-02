import 'package:creatures_rogue/game/components/creatures/abilities/disparada_congelante.dart';
import 'package:creatures_rogue/game/components/creatures/abilities/tiro_de_gelo.dart';
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
import 'abilities/baforada_de_cinzas.dart';
import 'abilities/bico_eletrico.dart';
import 'abilities/bolha_protetora.dart';
import 'abilities/brado.dart';
import 'abilities/casco_fechado.dart';
import 'abilities/corrente_estatica.dart';
import 'abilities/cuspe_de_semente.dart';
import 'abilities/disparada_flamejante.dart';
import 'abilities/enraizar.dart';
import 'abilities/ericar.dart';
import 'abilities/escudo_de_espinhos.dart';
import 'abilities/folhas_navalha.dart';
import 'abilities/estocada_relampago.dart';
import 'abilities/investida_da_lanca.dart';
import 'abilities/jato_aquatico.dart';
import 'abilities/bola_dagua.dart';
import 'abilities/jogada_de_corpo.dart';
import 'abilities/mega_soco.dart';
import 'abilities/mergulho_e_estouro.dart';
import 'abilities/mordida.dart';
import 'abilities/rajada_de_brasa.dart';
import 'abilities/recolher_no_casco.dart';
import 'base_stats.dart';
import 'creature_data.dart';
import 'creature_type.dart';
import 'passives/rastro_flamejante.dart';
import 'passives/casco_reflexivo.dart';
import 'passives/bolha_autonoma.dart';
import 'passives/corrente_reflexa.dart';
import 'passives/tornado_residual.dart';
import 'passives/salto_aquatico.dart';
import 'passives/brado_reflexo.dart';
import 'passives/reflexo_eletrico.dart';
import 'passives/bomba_na_esquiva.dart';
import 'passives/pecoenha_reflexiva.dart';
import 'passives/rastro_congelante.dart';
import 'passives/retaliacao_eletrica.dart';
import 'passives/fumaca_ao_lacar.dart';
import 'passives/raizes_do_laco.dart';
import 'passives/investida_predatoria.dart';
import 'passives/golpe_de_lanca.dart';
import '../effects/movement_animator.dart';
import '../enemies/creatures/ave_eletrica_enemy.dart';
import '../enemies/creatures/bomba_fogo_enemy.dart';
import '../enemies/creatures/caranguejo_ermitao_enemy.dart';
import '../enemies/creatures/cobra_agua_enemy.dart';
import '../enemies/creatures/grilo_eletrico_enemy.dart';
import '../enemies/creatures/leao_eletrico_enemy.dart';
import '../enemies/creatures/ourico_eletrico_enemy.dart';
import '../enemies/creatures/pinguim_agua_enemy.dart';
import '../enemies/creatures/roedor_fogo_enemy.dart';
import '../enemies/creatures/sapo_agua_enemy.dart';
import '../enemies/creatures/slime_planta_enemy.dart';
import '../enemies/creatures/tartaruga_planta_enemy.dart';
import '../enemies/creatures/toco_planta_enemy.dart';
import '../enemies/creatures/tornado_fogo_enemy.dart';
import '../enemies/creatures/tubarao_agua_enemy.dart';
import '../enemies/creatures/urso_planta_enemy.dart';

class CreatureRegistry {
  static final CreatureData roedorFogo = CreatureData(
    id: 'roedor_fogo',
    nome: 'Torchmin',
    spritePath: 'actors/ratFogo.png',
    tipo: CreatureType.fogo,
    corClara: Palette.laranja,
    corEscura: Palette.vermelho,
    stats: BaseStats(maxHp: 8, speed: 70, defesa: 1, ataque: 3),
    ability1: RajadaDeBrasa(),
    ability2: DisparadaFlamejante(),
    moveAnim: MovementAnimation.caminhada,
    hitboxSize: Vector2(8, 10), 
    enemyBuilder: (pos, plr) => RoedorFogoEnemy(position: pos, playerTarget: plr),
    passive: RastroFlamejante(),
  );

  static final CreatureData tartarugaPlanta = CreatureData(
    id: 'tartaruga_planta',
    nome: 'Turtrent',
    spritePath: 'actors/tartPlanta.png',
    tipo: CreatureType.planta,
    corClara: Palette.verde,
    corEscura: Palette.marromEsc,
    stats: BaseStats(maxHp: 20, speed: 35, defesa: 4, ataque: 3),
    ability1: CuspeDeSemente(),
    ability2: CascoFechado(),
    moveAnim: MovementAnimation.arrastar,
    hitboxSize: Vector2(14, 14), 
    enemyBuilder: (pos, plr) => TartarugaPlantaEnemy(position: pos, playerTarget: plr),
    passive: CascoReflexivo(),
  );

  static final CreatureData sapoAgua = CreatureData(
    id: 'sapo_agua',
    nome: 'Frowago',
    spritePath: 'actors/sapoAgua.png',
    tipo: CreatureType.agua,
    corClara: Palette.azul,
    corEscura: Palette.indigo,
    stats: BaseStats(maxHp: 12, speed: 50, defesa: 2, ataque: 2),
    ability1: BolaDagua(),
    ability2: BolhaProtetora(),
    moveAnim: MovementAnimation.saltitar,
    hitboxSize: Vector2(12, 10), 
    enemyBuilder: (pos, plr) => SapoAguaEnemy(position: pos, playerTarget: plr),
    passive: BolhaAutonoma(),
  );

  static final CreatureData aveEletrica = CreatureData(
    id: 'ave_eletrica',
    nome: 'Garibirb',
    spritePath: 'actors/aveEletric.png',
    tipo: CreatureType.eletrico,
    corClara: Palette.amarelo,
    corEscura: Palette.laranja,
    stats: BaseStats(maxHp: 10, speed: 80, defesa: 3, ataque: 1),
    ability1: BicoEletrico(),
    ability2: CorrenteEstatica(),
    moveAnim: MovementAnimation.flutuar,
    hitboxSize: Vector2(9, 11),
    enemyBuilder: (pos, plr) => AveEletricaEnemy(position: pos, playerTarget: plr),
    passive: CorrenteReflexa(),
  );

  static final CreatureData cobraAgua = CreatureData(
    id: 'cobra_agua',
    nome: 'Cobra de Água',
    spritePath: 'actors/cobraAgua.png',
    tipo: CreatureType.agua,
    corClara: Palette.azul,
    corEscura: Palette.laranja,
    stats: BaseStats(maxHp: 18, speed: 48, defesa: 4, ataque: 4),
    ability1: JatoAquatico(),
    ability2: JogadaDeCorpo(),
    moveAnim: MovementAnimation.arrastar,
    hitboxSize: Vector2(9, 14),
    enemyBuilder: (pos, plr) => CobraAguaEnemy(position: pos, playerTarget: plr),
    passive: SaltoAquatico(),
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
    hitboxSize: Vector2(15, 16),
    enemyBuilder: (pos, plr) => UrsoPlantaEnemy(position: pos, playerTarget: plr),
    passive: BradoReflexo(),
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
    hitboxSize: Vector2(8, 10),
    enemyBuilder: (pos, plr) => GriloEletricoEnemy(position: pos, playerTarget: plr),
    passive: ReflexoEletrico(),
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
    hitboxSize: Vector2(8, 10),
    enemyBuilder: (pos, plr) => TornadoFogoEnemy(position: pos, playerTarget: plr),
    passive: TornadoResidual(),
  );

  static final CreatureData bombaFogo = CreatureData(
    id: 'bomba_fogo',
    nome: 'Bomba de Fogo',
    spritePath: 'actors/bombaFogo.png',
    tipo: CreatureType.fogo,
    corClara: Palette.burgundy,
    corEscura: Palette.roxoEsc,
    stats: BaseStats(maxHp: 10, speed: 70, defesa: 3, ataque: 4),
    ability1: DeixarBomba(),
    ability2: EsquivaBomba(),
    moveAnim: MovementAnimation.saltitar,
    hitboxSize: Vector2(8, 10),
    enemyBuilder: (pos, plr) => BombaFogoEnemy(position: pos, playerTarget: plr),
    passive: BombaNaEsquiva(),
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
    passive: PecoenhaReflexiva(),
  );

  static final CreatureData ouricoEletrico = CreatureData(
    id: 'ourico_eletrico',
    nome: 'Ouriço Elétrico',
    spritePath: 'actors/ouricoEletric.png',
    tipo: CreatureType.eletrico,
    corClara: Palette.amarelo,
    corEscura: Palette.cinzaEsc,
    stats: BaseStats(maxHp: 14, speed: 28, defesa: 5, ataque: 3),
    ability1: Ericar(),
    ability2: EscudoDeEspinhos(),
    moveAnim: MovementAnimation.caminhada,
    hitboxSize: Vector2(12, 12), 
    enemyBuilder: (pos, plr) => OuricoEletricoEnemy(position: pos, playerTarget: plr),
    passive: RetaliacaoEletrica(),
  );

  static final CreatureData caranguejoErmitao = CreatureData(
    id: 'caranguejo_fogo',
    nome: 'Caranguejo Ermitão de Fogo',
    spritePath: 'actors/caranguejoFogo.png',
    tipo: CreatureType.fogo,
    corClara: Palette.vermelho,
    corEscura: Palette.cinzaEsc,
    stats: BaseStats(maxHp: 18, speed: 34, defesa: 4, ataque: 3),
    ability1: BaforadaDeCinzas(),
    ability2: RecolherNoCasco(),
    moveAnim: MovementAnimation.arrastar,
    hitboxSize: Vector2(14, 12),
    enemyBuilder: (pos, plr) => CaranguejoErmitaoEnemy(position: pos, playerTarget: plr),
    passive: FumacaAoLacar(),
  );

  static final CreatureData pinguimAgua = CreatureData(
    id: 'pinguim_agua',
    nome: 'Pinguim de Agua',
    spritePath: 'actors/pinguimAgua.png',
    tipo: CreatureType.agua,
    corClara: Palette.azul,
    corEscura: Palette.azulEsc,
    stats: BaseStats(maxHp: 18, speed: 40, defesa: 4, ataque: 4),
    ability1: TiroDeGelo(),
    ability2: DisparadaCongelante(),
    moveAnim: MovementAnimation.caminhada,
    hitboxSize: Vector2(8, 14),
    enemyBuilder: (pos, plr) => PinguimAguaEnemy(position: pos, playerTarget: plr),
    passive: RastroCongelante(),
  );

  static final CreatureData tocoPlanta = CreatureData(
    id: 'toco_planta',
    nome: 'Toco de Madeira',
    spritePath: 'actors/tocoPlanta.png',
    tipo: CreatureType.planta,
    corClara: Palette.verdeEsc,
    corEscura: Palette.chocolate,
    stats: BaseStats(maxHp: 16, speed: 45, defesa: 2, ataque: 3),
    ability1: FolhasNavalha(),
    ability2: Enraizar(),
    moveAnim: MovementAnimation.saltitar,
    hitboxSize: Vector2(10, 10), 
    enemyBuilder: (pos, plr) => TocoPlantaEnemy(position: pos, playerTarget: plr),
    passive: RaizesDoLaco(),
  );

  static final CreatureData tubaraoAgua = CreatureData(
    id: 'tubarao_agua',
    nome: 'Tubarão de Água',
    spritePath: 'actors/tubaAgua.png',
    tipo: CreatureType.agua,
    corClara: Palette.azul,
    corEscura: Palette.royal,
    stats: BaseStats(maxHp: 20, speed: 40, defesa: 3, ataque: 5),
    ability1: Mordida(),
    ability2: MergulhoEEstouro(),
    moveAnim: MovementAnimation.caminhada,
    hitboxSize: Vector2(13, 15),
    enemyBuilder: (pos, plr) => TubaraoAguaEnemy(position: pos, playerTarget: plr),
    passive: InvestidaPredatoria(),
  );

  static final CreatureData leaoEletrico = CreatureData(
    id: 'leao_eletrico',
    nome: 'Leão Elétrico',
    spritePath: 'actors/gatoEletrico.png',
    tipo: CreatureType.eletrico,
    corClara: Palette.laranja,
    corEscura: Palette.chocolate,
    stats: BaseStats(maxHp: 20, speed: 55, defesa: 4, ataque: 4),
    ability1: EstocadaRelampago(),
    ability2: InvestidaDaLanca(),
    moveAnim: MovementAnimation.caminhada,
    hitboxSize: Vector2(10, 15),
    enemyBuilder: (pos, plr) => LeaoEletricoEnemy(position: pos, playerTarget: plr),
    passive: GolpeDeLanca(),
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
    slimePlanta,
    pinguimAgua,
    ouricoEletrico,
    caranguejoErmitao,
    tocoPlanta,
    tubaraoAgua,
    leaoEletrico,
  ];

  static CreatureData byId(String id) => all.firstWhere((c) => c.id == id);
}
