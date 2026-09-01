import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import '../enemy.dart';
import '../enemy_mixins.dart';

/// Tornado de Fogo Boss — "Furacão Carmesim": mesma perseguição e soco de
/// perto da normal, com um problema a mais pra resolver do lado do design.
///
/// Um boss que só ataca colado, contra jogador que sabe manter distância,
/// nunca ataca — a luta trava em "corre em círculo pra sempre". Fase 2
/// (≤50%) resolve isso com um **dash telegrafado**: se o jogador se afasta
/// demais, ele carrega em linha reta na última direção vista, furando o
/// espaço que só dava pra kitar. Fica exposto um instante depois — mesma
/// linguagem de janela-de-punição dos outros bosses.
class TornadoFogoBossEnemy extends Enemy with ChaseMovement, ShooterAttack {
  static const double _vidaInicial = 200.0; // 4x a normal (20)
  static const double _alcanceSoco = 34.0;
  static const double _fireRate = 1.1;
  static const double _alcanceSegundos = 0.15;

  /// Distância a partir da qual o dash é cogitado — só dispara quando o
  /// jogador já fugiu além do alcance do soco, não a qualquer afastamento.
  static const double _dashAlcanceGatilho = 60.0;
  static const double _dashTelegraph = 0.4;
  static const double _dashDuracao = 0.22;
  static const double _dashDistancia = 80.0;
  static const double _dashCooldown = 2.5;
  static const double _dashDano = 5.0;
  static const double _dashEmpurrao = 60.0;
  static const double _dashRecuperacao = 0.3;

  bool _faseDois = false;
  bool _dashTelegrafando = false;
  bool _dashEmAndamento = false;
  bool _dashRecuperando = false;
  double _dashTimer = 0.0;
  double _dashCooldownTimer = _dashCooldown; // pronto desde o começo
  Vector2 _dashDirecao = Vector2.zero();

  TornadoFogoBossEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         creature: CreatureRegistry.tornadoFogo,
         speed: 50.0,
         health: _vidaInicial,
         dmg: 6,
         bltSpeed: 260,
         bltImg: 'projeteis/soco.png',
         bltCor1: CreatureRegistry.tornadoFogo.corClara,
         bltCor2: CreatureRegistry.tornadoFogo.corEscura,
         size: Vector2(32, 32),        // dobro do padrão (16x16)
         hitboxSize: Vector2(18, 22),  // dobro do hitbox normal (9, 11)
         isPushable: false,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setupAttackAnimation(duration: 0.25);
  }

  @override
  void movimento(double dt) {
    if (!_faseDois && health <= _vidaInicial / 2) _faseDois = true;

    _dashCooldownTimer += dt;

    // Impacto acabou de bater: fica exposto, mesma janela de punição do resto.
    if (_dashRecuperando) {
      _dashTimer -= dt;
      animateMovement(dt, isMoving: false);
      if (_dashTimer <= 0) _dashRecuperando = false;
      return;
    }

    // Carregando em linha reta, na direção capturada no fim do telegrafo.
    if (_dashEmAndamento) {
      _dashTimer += dt;
      position += _dashDirecao * (_dashDistancia / _dashDuracao) * dt;

      if (_dashTimer >= _dashDuracao) {
        _dashEmAndamento = false;
        _dashRecuperando = true;
        _dashTimer = _dashRecuperacao;
        _bater();
      }
      return;
    }

    // Parado, contando o aviso — dá tempo de reagir antes da carga sair.
    if (_dashTelegrafando) {
      _dashTimer += dt;
      animateMovement(dt, isMoving: false);

      if (_dashTimer >= _dashTelegraph) {
        _dashTelegrafando = false;
        _dashEmAndamento = true;
        _dashTimer = 0.0;
        _dashDirecao = (playerTarget.absolutePosition - absolutePosition).normalized();
        GhostEffect.spawnTrail(
          visual: visual,
          add: (g) => parent?.add(g),
          overDuration: _dashDuracao,
        );
      }
      return;
    }

    if (updateAttack(dt, _fireRate, _socar)) return;

    final distancia = (playerTarget.absolutePosition - absolutePosition).length;

    // Anti-kite: só na fase 2, só quando o jogador já fugiu de verdade, e só
    // quando o dash não está em cooldown.
    if (_faseDois && distancia > _dashAlcanceGatilho && _dashCooldownTimer >= _dashCooldown) {
      _dashTelegrafando = true;
      _dashTimer = 0.0;
      _dashCooldownTimer = 0.0;
      spawnAlerta(duracao: _dashTelegraph);
      return;
    }

    if (wantsToShoot && distancia <= _alcanceSoco) {
      triggerAttack();
      return;
    }

    updateChaseMovement(dt);
  }

  void _socar() {
    final direcao = (playerTarget.absolutePosition - absolutePosition).normalized();
    shoot(direcao, lifeTime: _alcanceSegundos);
  }

  void _bater() {
    parent?.add(ExplosionHitbox(
      position: position.clone(),
      isEnemy: true, // sem isso a explosão não machuca o jogador
      dmg: _dashDano,
      knockback: _dashEmpurrao,
      size: Vector2(36, 36),
      cor1: CreatureRegistry.tornadoFogo.corClara,
      cor2: CreatureRegistry.tornadoFogo.corEscura,
    ));
  }

  @override
  void death() {
    CreatureProgress.instance.unlock('tornado_fogo');
    super.death();
  }
}
