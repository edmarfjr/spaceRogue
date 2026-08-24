import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Caranguejo Ermitão de Fogo Boss — mesma inversão da Tartaruga Ancestral:
/// o casco fechado deixa de ser a janela seguravazia e passa a ser o aviso —
/// o perigo é a REABERTURA, que espalha uma nuvem de cinza no chão ao redor
/// (área a evitar, não dano instantâneo). Fase 2 (≤50%) encurta o ciclo e a
/// nuvem dura mais.
class CaranguejoErmitaoBossEnemy extends Enemy with WanderMovement, ShooterAttack {
  static const double _vidaInicial = 104.0; // 4x a normal (26)
  static const double _fireRate = 2.2;

  static const double _tempoAteGuardarFase1 = 5.0;
  static const double _tempoAteGuardarFase2 = 3.5;
  static const double _duracaoGuardaFase1 = 1.8;
  static const double _duracaoGuardaFase2 = 1.2;
  static const double _reducaoGuardaFase1 = 0.8;
  static const double _reducaoGuardaFase2 = 0.95;
  static const double _cinzaDuracaoFase1 = 1.2;
  static const double _cinzaDuracaoFase2 = 1.8;
  static const double _cinzaRaioFase1 = 20.0;
  static const double _cinzaRaioFase2 = 26.0;
  static const double _cinzaDano = 3.0;

  static const double _cegueiraFumacaFase1 = 1.6;
  static const double _cegueiraFumacaFase2 = 2.4;
  static const double _lentidaoFumaca = 2.5;

  static const double _avisoAntesAbrir = 0.5;

  double _guardaTimer = 0.0;
  bool _guardando = false;
  bool _avisou = false;
  bool _faseDois = false;

  CaranguejoErmitaoBossEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.caranguejoErmitao,
         speed: 22.0,
         health: _vidaInicial,
         dmg: 3,
         bltSpeed: 60,
         bltImg: 'projeteis/proj3.png',
         bltCor1: CreatureRegistry.caranguejoErmitao.corClara,
         bltCor2: CreatureRegistry.caranguejoErmitao.corEscura,
         size: Vector2(32, 32),        // dobro do padrão (16x16)
         hitboxSize: Vector2(28, 24),  // dobro do hitbox normal (14, 12)
         isPushable: false,
       );

  double get _tempoAteGuardar => _faseDois ? _tempoAteGuardarFase2 : _tempoAteGuardarFase1;
  double get _duracaoGuarda => _faseDois ? _duracaoGuardaFase2 : _duracaoGuardaFase1;
  double get _reducaoGuarda => _faseDois ? _reducaoGuardaFase2 : _reducaoGuardaFase1;
  double get _cinzaDuracao => _faseDois ? _cinzaDuracaoFase2 : _cinzaDuracaoFase1;
  double get _cinzaRaio => _faseDois ? _cinzaRaioFase2 : _cinzaRaioFase1;
  double get _cegueiraFumaca => _faseDois ? _cegueiraFumacaFase2 : _cegueiraFumacaFase1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.35);
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    _guardaTimer += dt;

    if (_guardando) {
      if (!_avisou && _guardaTimer >= _duracaoGuarda - _avisoAntesAbrir) {
        _avisou = true;
        spawnAlerta(duracao: _avisoAntesAbrir);
      }

      if (_guardaTimer >= _duracaoGuarda) {
        _guardando = false;
        shieldVisualActive = false;
        _guardaTimer = 0.0;
        _avisou = false;
        damageReduction = 0.0;
        visual.scale = Vector2(visual.scale.x.isNegative ? -1.0 : 1.0, 1.0);
        _abrirComCinza();
      } else {
        final flip = visual.scale.x.isNegative ? -1.0 : 1.0;
        visual.scale = Vector2(1.15 * flip, 0.8);
      }
      return;
    }

    if (_guardaTimer >= _tempoAteGuardar) {
      _guardando = true;
      shieldVisualActive = true;
      _guardaTimer = 0.0;
      damageReduction = _reducaoGuarda;
      return;
    }

    if (updateAttack(dt, _fireRate, _baforar)) return;

    if (wantsToShoot) {
      triggerAttack();
      return;
    }

    updateWanderMovement(dt, minPause: 1.0, maxPause: 2.0);
  }

  void _baforar() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao);
  }

  /// Ao reabrir, o boss despeja as duas metades do kit de uma vez: cinza que
  /// machuca e fumaça que cega. O inimigo comum só solta a fumaça — é a
  /// escalada que separa os dois, não um padrão de tiro diferente.
  void _abrirComCinza() {
    parent?.add(Projectile(
      position: position.clone(),
      direction: Vector2.zero(),
      isEnemy: true,
      speed: 0,
      kbForce: 0,
      dmg: _cinzaDano,
      sprPath: 'projeteis/nuvemP.png',
      cor1: CreatureRegistry.caranguejoErmitao.corClara,
      cor2: CreatureRegistry.caranguejoErmitao.corEscura,
      lifeTime: _cinzaDuracao,
      atravessa: 10,
      atravessaObstaculos: true,
      size: Vector2.all(_cinzaRaio),
      radius: _cinzaRaio / 2,
    ));

    parent?.add(Projectile(
      position: position.clone(),
      direction: Vector2.zero(),
      isEnemy: true,
      speed: 0,
      dmg: 0,
      kbForce: 0,
      sprPath: 'projeteis/nuvem.png',
      cor1: CreatureRegistry.caranguejoErmitao.corClara,
      cor2: CreatureRegistry.caranguejoErmitao.corEscura,
      cegoDuracao: _cegueiraFumaca,
      lentidaoDuracao: _lentidaoFumaca,
      lifeTime: _cinzaDuracao,
      atravessa: 10,
      atravessaObstaculos: true,
      size: Vector2.all(_cinzaRaio),
      radius: _cinzaRaio / 2,
    ));
  }

  @override
  void death() {
    CreatureProgress.instance.unlock('caranguejo_fogo');
    super.death();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is WallBarrier || other is Obstacle) {
      if (!isPhysicsCollision(other)) return;
      cancelWander();
    }
  }
}
