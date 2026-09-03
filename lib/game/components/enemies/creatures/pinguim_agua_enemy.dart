import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Pinguim de Água como inimigo: o único do elenco que te acerta DEPOIS de
/// você já ter desviado.
///
/// O tiro de gelo estilhaça pra trás (ver `estilhaca` no Projectile). Contra
/// quem fica parado isso não vale nada — o tiro acerta e os cacos voltam pro
/// pinguim, longe de você. O golpe é contra quem desvia: o tiro passa reto,
/// morre alguns passos adiante, e os três cacos varrem a MESMA faixa de volta.
///
/// Todo atirador daqui ensina "desvie uma vez". Esse ensina "desvie e continue
/// andando", que é leitura nova no elenco.
class PinguimAguaEnemy extends Enemy with WanderMovement, ShooterAttack {
  static const double _fireRate = 2.6;

  static const double _velocidadeTiro = 70.0;

  /// Quanto o tiro passa ALÉM do jogador antes de estilhaçar. O tempo de voo é
  /// calculado a partir da distância no momento do disparo, não fixo: com um
  /// valor fixo o tiro estouraria antes de chegar em quem está longe, e os
  /// cacos voltariam sem nunca cruzar o jogador. Assim o estouro cai sempre
  /// logo atrás dele, que é o que faz a varrida de volta valer.
  static const double _sobraAlemDoJogador = 24.0;

  /// Limites do tempo de voo, pra encostado e pra sala inteira.
  static const double _vooMinimo = 0.35;
  static const double _vooMaximo = 3.0;

  PinguimAguaEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.pinguimAgua,
         speed: 20.0, // stats.speed 34 → anda pouco, o perigo é o tiro
         health: 15,  // stats.maxHp 18 / defesa 4 → aguenta troca
         dmg: 1,
         bltSpeed: _velocidadeTiro,
         bltImg: 'projeteis/proj1.png',
         bltCor1: CreatureRegistry.pinguimAgua.corClara,
         bltCor2: CreatureRegistry.pinguimAgua.corEscura,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Tell longo de propósito: o truque só é justo se você tiver tempo de ler
    // a linha do tiro antes de escolher pra onde desviar.
    setupAttackAnimation(duration: 0.35, telegraph: 0.6);
  }

  @override
  void movimento(double dt) {
    if (updateAttack(dt, _fireRate, _tiroDeGelo)) return;

    if (wantsToShoot) {
      triggerAttack();
      return;
    }

    updateWanderMovement(dt, minPause: 1.0, maxPause: 2.0);
  }

  /// Não usa `shoot()` porque o herdado não sabe estilhaçar — precisa do
  /// `estilhaca` e do tempo de voo casados.
  void _tiroDeGelo() {
    final ate = playerTarget.absolutePosition - absolutePosition;
    final direcao = ate.normalized();
    final tempoDeVoo =
        ((ate.length + _sobraAlemDoJogador) / _velocidadeTiro).clamp(_vooMinimo, _vooMaximo);

    parent?.add(Projectile(
      owner: this,
      position: position.clone() + direcao * size.x / 2,
      direction: direcao,
      isEnemy: true,
      speed: _velocidadeTiro,
      dmg: dmg.toDouble(),
      sprPath: bltImg,
      cor1: bltCor1,
      cor2: bltCor2,
      tipo: CreatureRegistry.pinguimAgua.tipo,
      lifeTime: tempoDeVoo,
      estilhaca: true,
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
