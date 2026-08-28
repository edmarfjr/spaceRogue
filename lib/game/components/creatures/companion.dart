import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/damageable_by_enemy.dart';
import 'package:creatures_rogue/game/components/creatures/movement_host.dart';
import 'package:creatures_rogue/game/components/effects/movement_animator.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/enemies/enemy_mixins.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
import '../map/obstacle.dart';

/// Postura do grupo (PIVOT_TREINADOR.md §2.1/§2.1.1) — override de baixo nível
/// que o treinador cicla tocando no retrato da criatura na Hud. A natureza
/// (`CompanionBehavior`) é fixa por criatura e decide o padrão default;
/// postura é a correção momentânea que o jogador aplica em cima dela:
/// [seguir] não muda nada (natureza roda normal), [agressivo] força
/// perseguição mesmo em criaturas `guarda`/`orbital`, [segurar] cancela
/// qualquer movimento (a criatura ainda atira sozinha se um hostil aparecer
/// no alcance — só não persegue nem orbita).
enum CompanionPostura { seguir, agressivo, segurar }

/// Uma criatura invocada, agindo por conta própria (ver PIVOT_TREINADOR.md).
/// A natureza (`creatureData.companionBehavior`) decide só o MOVIMENTO — ver
/// [_updateMovement]; disparo autônomo de `ataque` contra o hostil mais
/// próximo vale pras três naturezas igual (ver [_updateAimAndFire]). Ainda
/// um `Companion` só por vez — grupo de três é fase 5b.
///
/// Simplificação desta fase, registrada e não escondida: sem a bolha visual
/// de habilidades defensivas — `shieldVisualActive` (de `AbilityUser`) já
/// muda de valor corretamente, só não há `SpriteComponent` desenhando a
/// bolha ainda. O escudo passivo (`shieldMax`/`shield`) já existe, mesma
/// fórmula do `Player` — sem ele, com os HPs de criatura jogável baixos
/// (ex.: 3 no Roedor de Fogo), o companion morria na primeira sala.
class Companion extends PositionComponent
    with
        CollisionCallbacks,
        HasGameRef,
        MovementHost,
        AbilityUser,
        DamageableByEnemy,
        ChaseMovement {
  final Player trainer;

  @override
  final CreatureData creatureData;

  /// Raio de coleira: dentro dele, o companion não persegue o treinador —
  /// só o inimigo mais próximo, se houver um a atirar.
  final double leashRadius;

  late final SpriteComponent _visual;
  late final Vector2 _visualBasePosition;
  late final MovementAnimator _moveAnimator;
  late RectangleHitbox _combatHitbox;
  late RectangleHitbox _physicsHitbox;

  double maxHealth;
  double currentHealth;

  /// Escudo passivo — mesma fórmula e regra do `Player`: segunda barra,
  /// absorve dano antes do HP, regenera sozinho com o tempo.
  //double shieldMax;
 // double shield;
 // double shieldRegenAmount = 1.0;
 // double shieldRegenInterval = 5.0;
 // double _shieldRegenTimer = 0.0;

  double _invulnerabilityTimer = 0.0;
  final double _invulnerabilityDuration = 1.0;

  double _lentidaoTimer = 0.0;

  /// Multiplicador de cadência do companion (upgrade de run — ver
  /// PIVOT_TREINADOR.md §3.7). Fixo em 1.0 até a fase de upgrades do
  /// treinador existir de verdade.
  double cdMult = 1.0;

  /// Ver [CompanionPostura]. Reseta pra `seguir` a cada desmaio/revive — é um
  /// `Companion` novo, sem estado herdado do anterior.
  CompanionPostura postura = CompanionPostura.seguir;

  void ciclarPostura() {
    postura = CompanionPostura.values[(postura.index + 1) % CompanionPostura.values.length];
  }

  Vector2 _lockedAb1Direction = Vector2(0, 1);

  double _cooldown1 = 0.0;
  double _cooldownMax1 = 1.0;

  /// Fração restante de cooldown (0 = pronto) — lido pela Hud.
  double get ability1CooldownFraction => (_cooldown1 / _cooldownMax1).clamp(0.0, 1.0);

  // --- Indicador de vida/escudo acima do sprite ---
  // O treinador não tem HP visível de criatura nenhuma na Hud (só o dele
  // próprio, ver hud.dart) — sem isso, morrer de dano invisível lê como
  // injusto. Desenho no próprio `render`, não um SpriteComponent filho:
  // são só dois retângulos, não precisa de asset nem de onLoad assíncrono.
  static final Paint _barraMoldura = Paint()..color = Palette.preto;
  static final Paint _barraFundo = Paint()..color = Palette.cinzaEsc;
  static final Paint _hpPreenchimento = Paint()..color = Palette.verde;
 // static final Paint _shieldPreenchimento = Paint()..color = Palette.azul;
  static const double _barraLargura = 14.0;
  static const double _barraAltura = 2.0;

  void _renderBarraStatus(Canvas canvas) {
    final totalPontos = maxHealth;// + shieldMax;
    if (totalPontos <= 0) return;

    final pxPorPonto = min(2.0, _barraLargura / totalPontos);
    final larguraHp = pxPorPonto * maxHealth;
//    final larguraEscudo = pxPorPonto * shieldMax;
    final left = (size.x - larguraHp /* - larguraEscudo */) / 2;
    const top = -5.0;

    canvas.drawRect(
      Rect.fromLTWH(left - 1, top - 1, larguraHp /* + larguraEscudo */ + 2, _barraAltura + 2),
      _barraMoldura,
    );
    canvas.drawRect(Rect.fromLTWH(left, top, larguraHp, _barraAltura), _barraFundo);
    canvas.drawRect(
      Rect.fromLTWH(left, top, pxPorPonto * currentHealth, _barraAltura),
      _hpPreenchimento,
    );

  /*  if (shieldMax > 0) {
      canvas.drawRect(
        Rect.fromLTWH(left + larguraHp, top, larguraEscudo, _barraAltura),
        _barraFundo,
      );
      canvas.drawRect(
        Rect.fromLTWH(left + larguraHp, top, pxPorPonto * shield, _barraAltura),
        _shieldPreenchimento,
      );
    }
    */
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderBarraStatus(canvas);
    canvas.drawCircle(Offset(size.x/2,size.y), _physicsHitbox.size.x/2 + 2, Paint()..color=Palette.preto..style=PaintingStyle.stroke..strokeWidth=3);
    canvas.drawCircle(Offset(size.x/2,size.y), _physicsHitbox.size.x/2 + 2, Paint()..color=Palette.branco..style=PaintingStyle.stroke..strokeWidth=1);
  }

  Vector2 offPos = Vector2.zero();

  Companion({
    required Vector2 position,
    required this.trainer,
    required this.creatureData,
    this.leashRadius = 28.0,
  }) : maxHealth = creatureData.stats.maxHp,
       currentHealth = creatureData.stats.maxHp,
     //  shieldMax = creatureData.stats.shieldMax,
     //  shield = creatureData.stats.shieldMax,
       super(size: Vector2(16, 16), anchor: Anchor.center, position: position);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    offPos = Vector2(Random().nextDouble()*2 - 1, Random().nextDouble()*2 - 1) * 16 ;

    final ui.Image spriteImage = await PaletteSwapper.createSwappedImage(
      imagePath: creatureData.spritePath,
      lightGrayReplacement: creatureData.corClara,
      darkGrayReplacement: creatureData.corEscura,
    );

    _visualBasePosition = Vector2(size.x / 2, size.y);
    _moveAnimator = MovementAnimator(creatureData.moveAnim);

    _visual = SpriteComponent(
      sprite: Sprite(spriteImage),
      size: size,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition.clone(),
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 1,
    );
    add(_visual);

    final hitboxSize = creatureData.hitboxSize;
    _combatHitbox = RectangleHitbox(
      size: hitboxSize,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition,
      collisionType: CollisionType.active,
    );
    add(_combatHitbox);

    _physicsHitbox = RectangleHitbox(
      size: Vector2(hitboxSize.x, hitboxSize.x * 0.5),
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, hitboxSize.y / 2),
      collisionType: CollisionType.active,
    );
    add(_physicsHitbox);

    final shadow = CircleComponent(
      radius: hitboxSize.x / 2,
      anchor: Anchor.center,
      position: _visualBasePosition,
      paint: Paint()..color = Palette.preto,
      priority: -1,
    )..scale = Vector2(1.2, 0.75);
    add(shadow);
  }

  // --- MovementHost ---
  @override
  double get speed => creatureData.stats.speed * lentidaoFator;

  @override
  SpriteComponent get visual => _visual;

  @override
  RectangleHitbox get enemyHitbox => _combatHitbox;

  @override
  RectangleHitbox get physicsHitbox => _physicsHitbox;

  /// Consumido por `ChaseMovement` (guarda e cacador). `orbital` não usa
  /// `ChaseMovement` — tem posição própria em [_updateOrbital] — mas precisa
  /// satisfazer o getter mesmo assim; treinador é o valor neutro.
  @override
  PositionComponent get currentTarget {
    if (postura == CompanionPostura.agressivo ||
        creatureData.companionBehavior == CompanionBehavior.cacador) {
      return _nearestEnemy() ?? trainer;
    }
    return trainer;
  }

  @override
  void animateMovement(double dt, {required bool isMoving, double horizontalDir = 0.0}) {
    _moveAnimator.update(
      visual: _visual,
      basePosition: _visualBasePosition,
      isMoving: isMoving,
      horizontalDir: horizontalDir,
      dt: dt,
    );
  }

  // --- AbilityUser ---
  @override
  Vector2 get lockedAb1Direction => _lockedAb1Direction;

  /// A criatura só tem uma habilidade ativa agora (PIVOT_TREINADOR.md, pedido
  /// do usuário) — `ability2` continua nos dados de `CreatureData`, só
  /// ninguém aqui a executa. O getter existe só pra satisfazer o contrato de
  /// `AbilityUser`; valor neutro, nunca lido de verdade.
  @override
  Vector2 get lockedAb2Direction => _lockedAb1Direction;

  /// Bombas são recurso do treinador, não do companion (PIVOT_TREINADOR.md
  /// §3.2) — delega direto.
  @override
  int get bombsAmount => trainer.bombsAmount;
  @override
  void placeBomb(Vector2 dir) => trainer.placeBomb(dir);

  @override
  void grantInvulnerability(double seconds) {
    if (seconds > _invulnerabilityTimer) _invulnerabilityTimer = seconds;
  }

  @override
  void startJump({
    required Vector2 direction,
    required double distance,
    required double duration,
    double height = 16.0,
    VoidCallback? onLand,
  }) {
    // Salto genérico (Jogada de Corpo etc.) não existe ainda para companion
    // nesta fase — sem uso confirmado por nenhuma das quatro criaturas
    // iniciais como natureza guarda, então fica de fora até um caso real
    // pedir por ele.
    onLand?.call();
  }

  // --- DamageableByEnemy ---
  @override
  void takeDamage(double amount) {
    if (_invulnerabilityTimer > 0) return;
    double amountFinal = amount * (1 - damageReduction);
    if (amountFinal <= 0) return;
    GameAudio.instance.play(Sfx.hit);

    _invulnerabilityTimer = _invulnerabilityDuration;

    parent?.add(TextEffect.dano(
      amountFinal,
      position: position.clone() + Vector2(0, -size.y / 2 - 4),
      color: Palette.vermelho,
    ));

    if (shieldHits > 0) {
      shieldHits--;
      if (shieldHits <= 0) shieldVisualActive = false;
      return;
    }

    // Escudo passivo (defesa) absorve antes do HP — segunda barra, não a
    // bolha de habilidade (shieldHits), que já retornou acima se ativa.
    // Mesma regra do Player: o excedente passa pro HP, sem arredondar pra
    // cima (ver comentário equivalente em player.dart).
   /* if (shield > 0) {
      final absorvido = amountFinal > shield ? shield : amountFinal;
      shield -= absorvido;
      amountFinal -= absorvido;
      if (shield < 0) shield = 0;
      if (amountFinal <= 0) return;
    }
*/
    currentHealth -= amountFinal;
    if (currentHealth <= 0) _pocketarPorMorte();
  }

  @override
  void aplicarLentidao(double duracao, {double fator = 0.5}) {
    if (duracao > _lentidaoTimer) _lentidaoTimer = duracao;
    if (fator < lentidaoFator) lentidaoFator = fator;
  }

  @override
  void aplicarCegueira(double duracao) {
    if (duracao > cegoTimer) cegoTimer = duracao;
  }

  @override
  void applyKnockback(Vector2 sourcePosition, double force) {
    final direction = absolutePosition - sourcePosition;
    if (direction.length == 0) return;
    knockbackVelocity = direction.normalized() * force;
  }

  /// HP zerado em combate recolhe pro bolso — substitui o desmaio+timer fixo
  /// de antes (pedido do usuário, ver checklist do PIVOT_TREINADOR.md).
  /// Delega tudo (salvar vida, efeito de recall, remoção do mundo) pra
  /// `CreaturesRogueGame.pocketarSlot`, a mesma rotina que a ação em massa de
  /// recolher/liberar usa — os dois motivos de recolher (morte em combate,
  /// botão do jogador) viram exatamente o mesmo estado. `indexOf` funciona
  /// porque `Companion` não sobrescreve `==` — é comparação de identidade.
  void _pocketarPorMorte() {
    final jogo = game;
    if (jogo is! CreaturesRogueGame) return;
    final slot = jogo.companions.indexOf(this);
    if (slot != -1) jogo.pocketarSlot(slot);
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = ySortPriority(position.y + size.y / 2);

    if (_invulnerabilityTimer > 0) _invulnerabilityTimer -= dt;
    if (_cooldown1 > 0) _cooldown1 -= dt;
    if (_lentidaoTimer > 0) {
      _lentidaoTimer -= dt;
      if (_lentidaoTimer <= 0) lentidaoFator = 1.0;
    }
    if (cegoTimer > 0) cegoTimer -= dt;

   /* if (shield < shieldMax) {
      _shieldRegenTimer += dt;
      if (_shieldRegenTimer >= shieldRegenInterval) {
        _shieldRegenTimer = 0.0;
        shield = (shield + shieldRegenAmount).clamp(0.0, shieldMax);
      }
    }
*/
    if (!knockbackVelocity.isZero()) {
      position += knockbackVelocity * dt;
      final drop = 240.0 * dt;
      if (knockbackVelocity.length < drop) {
        knockbackVelocity.setZero();
      } else {
        knockbackVelocity -= knockbackVelocity.normalized() * drop;
      }
      return;
    }

    _updateAimAndFire();
    _updateMovement(dt);
  }

  /// A mira (para a habilidade autônoma) é sempre o inimigo mais próximo,
  /// restrita à sala atual, igual à mira do jogador antes deste pivô.
  Enemy? _nearestEnemy() {
    final room = currentRoom;
    final enemies = parent?.children.whereType<Enemy>() ?? const <Enemy>[];

    Enemy? nearest;
    double nearestDistSq = double.infinity;
    for (final enemy in enemies) {
      if (enemy.enraizadoPeloLaco) continue;
      if (room != null &&
          !room.toAbsoluteRect().contains(
              Offset(enemy.absolutePosition.x, enemy.absolutePosition.y))) {
        continue;
      }
      final distSq = (enemy.absolutePosition - absolutePosition).length2;
      if (distSq < nearestDistSq) {
        nearestDistSq = distSq;
        nearest = enemy;
      }
    }
    return nearest;
  }

  /// Única habilidade ativa da criatura (PIVOT_TREINADOR.md, pedido do
  /// usuário) — sempre `ataque`, sempre autônoma: dispara sozinha contra o
  /// hostil mais próximo, sem override nenhum de botão/tecla. `ability2`
  /// continua nos dados de `CreatureData`, só não é chamada por ninguém aqui.
  void _updateAimAndFire() {
    final target = _nearestEnemy();

    if (creatureData.ability1.target == AbilityTarget.enemyDir) {
      if (target != null) {
        final delta = target.absolutePosition - absolutePosition;
        if (delta.length != 0) _lockedAb1Direction = delta.normalized();
      }
    } else if (creatureData.ability1.target == AbilityTarget.plrDir) {
      _lockedAb1Direction = (_visual.isFlippedHorizontally ? Vector2(-1, 0) : Vector2(1, 0));
    }

    if (_cooldown1 > 0) return;
    if (target == null) return; // sem hostil à vista, nada pra atirar
    if (!creatureData.ability1.canExecute(this)) return;

    creatureData.ability1.execute(this, _lockedAb1Direction);
    _cooldownMax1 = creatureData.ability1.cooldown * cdMult;
    _cooldown1 = _cooldownMax1;
  }

  void _updateMovement(double dt) {
    // A perseguição da coleira é reta, sem pathfinding — atravessar uma porta
    // depende de a linha reta até o treinador passar pelo vão dela, e uma
    // parede no meio do caminho deixa o companion raspando nela pra sempre
    // (mesma limitação que `ChaseMovement` já tem contra inimigo). Detectável
    // e resolvível sem pathfinding de verdade: se o treinador mudou de sala,
    // o companion nunca vai alcançar por conta própria — teleporta pra perto
    // dele em vez de tentar. Comparar por sala em vez de por distância evita
    // teletransportar um companion que só está longe dentro da MESMA sala.
    final salaTreinador = trainer.currentRoom;
    final salaPropria = currentRoom;
    if (salaPropria != null && salaTreinador != null && salaPropria != salaTreinador) {
      position = trainer.position + Vector2(16, 0);
      knockbackVelocity = Vector2.zero();
      return;
    }

    // Postura (PIVOT_TREINADOR.md §2.1.1) é a correção momentânea do
    // treinador em cima da natureza fixa: `segurar` cancela qualquer
    // movimento (a criatura ainda atira sozinha se um hostil surgir no
    // alcance, só não sai do lugar) e `agressivo` força o padrão `cacador`
    // mesmo numa criatura `guarda`/`orbital`. `seguir` não muda nada — a
    // natureza roda como sempre rodou.
    if (postura == CompanionPostura.segurar) {
      animateMovement(dt, isMoving: false);
      return;
    }

    final comportamentoEfetivo = postura == CompanionPostura.agressivo
        ? CompanionBehavior.cacador
        : creatureData.companionBehavior;

    if (comportamentoEfetivo == CompanionBehavior.orbital) {
      _updateOrbital(dt);
      return;
    }

    // Caçador sem coleira enquanto houver hostil na sala — um caçador com
    // coleira é só um guarda com passo extra, não prova nada de diferente
    // (ver PIVOT_TREINADOR.md §3.6). Sem hostil, cai pro mesmo comportamento
    // de `guarda` abaixo.
    //
    // `ChaseMovement` só para de andar a 1px do alvo (feito pra inimigo
    // perseguindo o treinador, que tem contato como golpe). Sem um raio de
    // engajamento aqui, o caçador fechava até encostar no inimigo e apanhava
    // à queima-roupa de qualquer coisa telegrafada/explosiva até morrer —
    // ele tem alcance pra atirar de longe, não precisa (nem deveria) chegar
    // perto. `_cacadorEngageRange` para o avanço assim que dá pra atirar;
    // `_updateAimAndFire` continua disparando nessa distância igual.
    if (comportamentoEfetivo == CompanionBehavior.cacador) {
      final hostil = _nearestEnemy();
      if (hostil != null) {
        final distHostil = (hostil.absolutePosition - absolutePosition).length;
        if (distHostil > _cacadorEngageRange) {
          updateChaseMovement(dt);
        } else {
          animateMovement(dt, isMoving: false);
        }
        return;
      }
    }

    final distancia = ((trainer.absolutePosition - offPos) - absolutePosition).length;

    if (distancia > leashRadius) {
      updateChaseMovement(dt);
    } else {
      animateMovement(dt, isMoving: false);
    }
  }

  /// Distância que o caçador mantém do alvo antes de parar de avançar.
  /// Compartilhada entre os cinco caçadores — `Ability` não expõe alcance
  /// próprio, só cada implementação sabe o dela — então o valor é calibrado
  /// pela mais curta: `Mordida` (Tubarão de Água) nasce a 10px na frente de
  /// quem usa e some por volta de mais 10-15px de raio. Com os 40px
  /// anteriores a mordida nascia longe demais e nunca alcançava o alvo — o
  /// resto (todos projétil de verdade, que viajam sozinhos depois de
  /// disparados) não se importa com a distância de parada, então dá pra
  /// puxar geral pra perto sem perder nada neles.
  static const double _cacadorEngageRange = 18.0;

  double _orbitAngle = 0.0;
  static const double _orbitRadius = 24.0;
  static const double _orbitAngularSpeed = 1.6; // rad/s

  /// Natureza `orbital`: nunca persegue nada, sempre circula o treinador a
  /// raio fixo. Não usa `ChaseMovement` — a posição é calculada direto em
  /// coordenadas polares em torno do treinador. Escreve `position` toda
  /// frame, então um empurrão de parede no `onCollision` some no frame
  /// seguinte (aceitável: sem isso o companion nunca fica preso perto de
  /// parede, só treme visualmente por um frame — ver PIVOT_TREINADOR.md §3.6).
  void _updateOrbital(double dt) {
    _orbitAngle += _orbitAngularSpeed * dt;
    final offset = Vector2(cos(_orbitAngle), sin(_orbitAngle)) * _orbitRadius;
    position = trainer.position + offset;

    // Direção tangencial ao círculo — o que dá a leitura de "girando", não
    // "tremendo": vira de acordo com o lado do círculo em que está indo.
    final horizontalDir = -sin(_orbitAngle);
    animateMovement(dt, isMoving: true, horizontalDir: horizontalDir);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is WallBarrier || other is Obstacle) {
      if (!_physicsHitbox.toAbsoluteRect().overlaps(other.toAbsoluteRect())) return;

      final empurrao = empurraoParaFora(
        corpo: _physicsHitbox.toAbsoluteRect(),
        alvo: other.toAbsoluteRect(),
      );
      if (empurrao.isZero()) return;
      position += empurrao;
    }
  }
}
