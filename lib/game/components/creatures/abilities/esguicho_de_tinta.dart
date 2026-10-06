import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Calamarin — botão B. Esquiva com i-frames na direção da mira, deixando no
/// ponto de partida uma nuvem de tinta que cega quem entra.
///
/// A nuvem usa a mesma fumaça do Hermiton (`projeteis/nuvem.png`), em tons
/// escuros. Ela NÃO segura tiro (`interageComProjeteis: false`): bloquear
/// projétil é o ganho da evolução, `CortinaDeTinta`.
class EsguichoDeTinta extends Ability {
  final double distancia;
  final double duracao;
  final double cegueira;
  final double vidaNuvem;

  const EsguichoDeTinta({
    this.distancia = 32,
    this.duracao = 0.15,
    this.cegueira = 1.5,
    this.vidaNuvem = 3.0,
  }) : super(
         nome: 'Esguicho de Tinta',
         descricao: 'Esquiva que deixa uma nuvem de tinta que cega.',
         cooldown: 4.0,
         target: AbilityTarget.plrDir,
         tipo: AbilityTipo.esquiva,
       );

  /// Montagem da nuvem, compartilhada com a evolução e com o Calamarin
  /// inimigo/boss — que só mudam tamanho, duração, lado e o bloqueio de tiro.
  static Projectile nuvem({
    required PositionComponent dono,
    required Vector2 posicao,
    required double cegueira,
    required double vida,
    required double lado,
    bool isEnemy = false,
    bool bloqueiaTiro = false,
  }) {
    return Projectile(
      owner: dono,
      position: posicao,
      direction: Vector2.zero(),
      speed: 0,
      dmg: 0,
      kbForce: 0,
      isEnemy: isEnemy,
      sprPath: 'projeteis/nuvem.png',
      cor1: Palette.cinzaEsc,
      cor2: Palette.preto,
      cegoDuracao: cegueira,
      atravessa: 100,
      size: Vector2.all(lado),
      lifeTime: vida,
      radius: lado / 2,
      playSfx: false,
      interageComProjeteis: bloqueiaTiro,
      engoleProjeteis: bloqueiaTiro,
    );
  }

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.grantInvulnerability(duracao);
    user.parent?.add(
      nuvem(
        dono: user,
        posicao: user.position.clone(),
        cegueira: cegueira,
        vida: vidaNuvem,
        lado: 24,
      ),
    );
    GhostEffect.spawnTrail(
      visual: user.visual,
      add: (g) => user.parent?.add(g),
      overDuration: duracao,
    );
    user.add(
      MoveByEffect(
        user.dashOffsetLivre(-dir, distancia),
        EffectController(duration: duracao),
      ),
    );
  }
}
