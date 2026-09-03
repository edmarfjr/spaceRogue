import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Caranguejo Ermitão de Fogo como inimigo: cospe baforadas curtas de cinza,
/// e de tempos em tempos se recolhe no casco (quase imune, parado) — mesmo
/// ciclo de guarda da Tartaruga, janela segura pro jogador reposicionar em
/// vez de gastar tiro. O boss inverte isso soltando cinza ao reabrir.
class CaranguejoErmitaoEnemy extends Enemy with WanderMovement, ShooterAttack {
  static const double _fireRate = 2.2;

  static const double _tempoAteGuardar = 5.0;
  static const double _duracaoGuarda = 2.0;
  static const double _reducaoGuarda = 0.8;

  static const double _duracaoFumaca = 2.5;
  static const double _cegueiraFumaca = 1.6;
  static const double _lentidaoFumaca = 2.0;

  double _guardaTimer = 0.0;
  bool _guardando = false;

  CaranguejoErmitaoEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.caranguejoErmitao,
         speed: 22.0, // stats.speed 34 → lento, mas menos que o ouriço
         health: 15,  // stats.maxHp 18 → tanque, mais frágil que a Tartaruga
         dmg: 1,
         bltSpeed: 60,
         bltImg: 'projeteis/proj3.png',
         bltCor1: CreatureRegistry.caranguejoErmitao.corClara,
         bltCor2: CreatureRegistry.caranguejoErmitao.corEscura,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.35);
  }

  @override
  void movimento(double dt) {
    _guardaTimer += dt;

    if (_guardando) {
      if (_guardaTimer >= _duracaoGuarda) {
        _guardando = false;
        shieldVisualActive = false;
        _guardaTimer = 0.0;
        damageReduction = 0.0;
        visual.scale = Vector2(visual.scale.x.isNegative ? -1.0 : 1.0, 1.0);
        _soltarFumaca();
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

  /// Ao reabrir o casco, despeja fumaça no próprio lugar. Não dá dano nenhum:
  /// ela cega e atrasa. É o espelho da habilidade jogável do caranguejo — e é
  /// o único inimigo do elenco que cega o jogador, então é aqui que a vinheta
  /// de cegueira entra em jogo.
  void _soltarFumaca() {
    parent?.add(Projectile(
      owner: this,
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
      atravessa: 10,
      atravessaObstaculos: true,
      lifeTime: _duracaoFumaca,
      size: Vector2.all(24),
      radius: 12,
    ));
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
