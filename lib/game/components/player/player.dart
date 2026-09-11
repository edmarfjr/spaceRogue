import 'dart:ui' as ui;
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/effects/condition_icons.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/UI/cooldown_ring_indicator.dart';
import 'package:creatures_rogue/game/components/UI/dynamic_joystick_component.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/damageable_by_enemy.dart';
//import 'package:creatures_rogue/game/components/creatures/passive.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/effects/movement_animator.dart';
import 'package:creatures_rogue/game/components/effects/text_effect.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/items/consumable_item.dart';
import 'package:creatures_rogue/game/components/map/dungeon_generator.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/projeteis/bomb.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:flutter/services.dart';
import '../map/obstacle.dart';

/// O jogador é a criatura ativa do grupo (ver PIVOT_CONTROLE_DIRETO.md) —
/// controle direto, sem ator "treinador" separado. `creatureData` não é
/// `final`: trocar de criatura ativa (`trocarCriatura`) muta esta mesma
/// instância em vez de recriar o componente — ver o comentário de
/// `trocarCriatura` pro motivo (RoomComponent guarda `player:` como campo
/// final).
class Player extends PositionComponent
    with
        CollisionCallbacks,
        HasGameRef,
        KeyboardHandler,
        AbilityUser,
        DamageableByEnemy {
  final DynamicJoystickComponent moveJoystick;

  /// Analógico direito — a direção que ele empurra (travada nos 4 eixos
  /// cardeais, ver [_direcaoAtaqueTravada]) É a habilidade 1, disparada
  /// enquanto ele estiver fora da zona morta. Substituiu botão/gesto pra
  /// habilidade 1 (twin-stick de eixos travados).
  final DynamicJoystickComponent aimJoystick;
  CreatureData creatureData;

  // Componente visual único, animado por transformação (escala/flip), não por troca de frame.
  // Não são `final`: `trocarCriatura` remonta tudo a partir da criatura nova
  // (ver `_montarVisualEHitbox`).
  late SpriteComponent visual;
  late Vector2 _visualBasePosition;
  late MovementAnimator _moveAnimator;

  late final SpriteComponent circDir;

  // Bolha desenhada por cima do player enquanto uma habilidade defensiva
  // (Bolha Protetora, Casco Fechado) está com o efeito ativo.
  // `shieldVisualActive` vem de AbilityUser.
  late SpriteComponent shieldVisual;

  // --- Colisão ---
  late RectangleHitbox playerHitbox; // Colisor de Combate (Corpo)
  late RectangleHitbox physicsHitbox; // Colisor de Física (Pés/Sombra)
  late CircleComponent shadow;

  /// `_montarVisualEHitbox` só remove componentes antigos a partir da
  /// segunda chamada (a primeira, em `onLoad`, não tem nada montado ainda).
  bool _visualPronto = false;

  final Vector2 _keyboardMove = Vector2.zero();

  /// Setas do teclado — equivalente do `aimJoystick` pro teclado (mesmo
  /// padrão do `_keyboardMove` pro `moveJoystick`). Ver
  /// [_direcaoAtaqueTravada].
  final Vector2 _keyboardAtaqueDir = Vector2.zero();

  double maxHealth;
  double currentHealth;

  /// Tempo desde o último golpe realmente recebido (resetado em
  /// `takeDamage`, mesmo ponto que dispara retaliação) — usado por passivas
  /// que observam o tempo passando (ex.: Bolha Autônoma, do Sapo de Água).
  double _tempoSemApanhar = 0.0;
  double get tempoSemApanhar => _tempoSemApanhar;

  double _invulnerabilityTimer = 0.0;
  final double _invulnerabilityDuration = 1.5;

  /// Escudo passivo derivado da defesa: uma segunda barra que absorve dano
  /// antes do HP e regenera sozinha com o tempo. Tamanho e taxa de regen são
  /// mutáveis (não final) porque upgrades e itens futuros vão alterá-los
  /// durante a run.
  double shieldMax;
  double shield;
  double shieldRegenAmount = 1.0;
  double shieldRegenInterval = 5.0;
  double _shieldRegenTimer = 0.0;

  /// Quanto falta pro escudo passivo ganhar a próxima carga (0 = acabou de
  /// regenerar, 1 = prestes a ganhar) — lido pela Hud pro indicador vertical.
  /// NÃO é a bolha de habilidade (`shieldVisualActive`); é o escudo derivado
  /// da defesa, o mesmo que os corações azuis já mostram por carga inteira.
  double get shieldRegenFraction =>
      (_shieldRegenTimer / shieldRegenInterval).clamp(0.0, 1.0);

  int bombsAmount = 3;

  double critChance = 5;
  double critMult = 1.5;

  /// Moedas da run, gastas nos balcões da loja (ver ShopStand). Zeram junto
  /// com o Player, ou seja, a cada run nova.
  int coins = 0;

  /// Inventário de itens de uso único: dois slots, cada um com no máximo um
  /// item. `null` = vazio. Uma lista de tamanho fixo em vez de dois campos
  /// porque os botões da tela são indexados (ver ConsumableSlotButton).
  final List<ConsumableType?> slots = [null, null];

  // --- Multiplicadores de upgrade da run ---
  // Ficam aqui, e não em BaseStats, porque BaseStats é `const` (compartilhado
  // entre todas as instâncias da criatura). Mesmo padrão do `lentidaoFator`
  // logo abaixo: o valor base nunca muda, quem multiplica é o getter.
  double velMult = 1.0;

  /// Multiplicador de cadência das duas habilidades — upgrade de run
  /// (`fireRateUp`). Reseta pra 1.0 em `trocarCriatura`: é a criatura ativa
  /// que atira, então o upgrade não atravessa a troca (mesma regra que
  /// sempre valeu enquanto isto vivia no `Companion`).
  double cdMult = 1.0;

  /// Dano do jogador. É `static` porque quem multiplica é o próprio projétil /
  /// explosão no momento do acerto (ver `Projectile.onCollision`), e eles não
  /// têm referência ao Player. Aplicar nas 34 habilidades seria 34 edições;
  /// aqui são duas. Zera no construtor, ou seja, a cada run nova. `static` faz
  /// sentido de novo com só um `Player` por vez (não há mais três instâncias
  /// simultâneas disputando o multiplicador).
  static double danoMult = 1.0;

  Vector2 velocity = Vector2.zero();
  Vector2 knockbackVelocity = Vector2.zero();
  Vector2 plrDir = Vector2(0, 1);

  double get maxSpeed =>
      creatureData.stats.speed *
      lentidaoFator *
      velMult *
      (_dentroGramaAlta ? gramaAltaFator : 1.0);

  /// Lentidão e cegueira são as únicas condições que atingem o jogador — DoT
  /// fica só do lado dos inimigos, que têm os ícones de condição pra mostrar.
  /// Aqui a leitura vem do próprio movimento e da vinheta (ver BlindOverlay).
  double lentidaoTimer = 0.0;
  double lentidaoFator = 1.0;
  double cegoTimer = 0.0;
  double cegoDuracaoInicial = 0.0;
  final double acceleration = 100.0;
  final double friction = 500.0;

  /// Metade da velocidade dentro de `GramaAlta` — terreno, não condição
  /// temporária, sem timer. `Player` tem dois hitboxes ativos
  /// (`playerHitbox`/`physicsHitbox`), então um único tile de grama pode
  /// disparar `onCollisionStart`/`onCollisionEnd` mais de uma vez, em pares
  /// fora de ordem entre os dois hitboxes. Guardar um `Set` das grama
  /// atualmente sobrepostas (em vez de um bool ligado/desligado) resolve
  /// isso sozinho: `add`/`remove` são idempotentes, e cada entrada/saída só
  /// é aceita quando `isPhysicsCollision` confirma o estado real dos PÉS
  /// naquele instante — não importa qual dos dois hitboxes disparou o
  /// evento. Ver `onCollisionStart`/`onCollisionEnd`.
  static const double gramaAltaFator = 0.5;
  final Set<GramaAlta> _gramaAltaSobrepostas = {};
  bool get _dentroGramaAlta => _gramaAltaSobrepostas.isNotEmpty;

  /// Visão limitada dentro de `Cogumelos` — mesmo motivo do Set acima
  /// (terreno, não debuff de inimigo: sem timer, dura enquanto os pés
  /// estiverem dentro). Antes isso chamava `aplicarCegueira` a cada frame de
  /// colisão, o que reiniciava o timer de 0.3s repetidamente e fazia a
  /// vinheta piscar (fecha, quase reabre, fecha de novo) em vez de segurar
  /// fechada — ver `BlindOverlay`, que lê `dentroCogumelo` direto, sem timer.
  final Set<Cogumelos> _cogumelosSobrepostos = {};
  bool get dentroCogumelo => _cogumelosSobrepostos.isNotEmpty;

  /// Direção de disparo de cada habilidade. `lockedAb1Direction` vem do
  /// analógico/setas (ver [_direcaoAtaqueTravada], twin-stick de eixos
  /// travados — não é mais mira automática). `lockedAb2Direction` continua
  /// recalculada todo frame em [_atualizarMira] (inimigo mais próximo ou
  /// direção que o sprite está olhando, conforme `Ability.target`).
  Vector2 lockedAb1Direction = Vector2(0, 1);
  Vector2 lockedAb2Direction = Vector2(0, 1);

  // --- Cooldown e input das duas habilidades ---
  double _cooldown1 = 0.0;
  double _cooldownMax1 = 1.0;
  double _cooldown2 = 0.0;
  double _cooldownMax2 = 1.0;

  /// Fração restante de cooldown (0 = pronto) — lida pela Hud.
  double get ability1CooldownFraction =>
      (_cooldown1 / _cooldownMax1).clamp(0.0, 1.0);
  double get ability2CooldownFraction =>
      (_cooldown2 / _cooldownMax2).clamp(0.0, 1.0);

  // --- Evolução (ver PIVOT_EVOLUCAO) ---
  /// XP da criatura ATIVA nesta run — só ela ganha XP de inimigo derrotado
  /// (ver `ganharXp`). Cada slot do grupo guarda o seu próprio quando não é
  /// a ativa (ver `CreaturesRogueGame.companionXp`), restaurado aqui na troca
  /// (`trocarCriatura`). Não sobrevive entre runs.
  double xp = 0.0;
  bool evoluida = false;

  /// Quanto de XP falta pra evoluir. Só uma constante por enquanto — todas
  /// as criaturas evoluem no mesmo ritmo.
  static const double xpParaEvoluir = 35.0;

  double get xpFracao => evoluida ? 1.0 : (xp / xpParaEvoluir).clamp(0.0, 1.0);

  /// Chamado por `Enemy.death()` quando a criatura ativa dá o golpe fatal.
  /// Sem efeito se esta criatura não tem forma evoluída desenhada
  /// (`creatureData.evoluir == null`) ou já evoluiu nesta run.
  ///
  /// `ganharXp` é chamado de dentro de `Enemy.death()`, que por sua vez roda
  /// de dentro do `onCollisionStart` de um projétil — ou seja, em PLENO
  /// meio da varredura de colisão do frame. Evoluir na hora remontaria
  /// `playerHitbox`/`physicsHitbox` (remove+add) com a varredura ainda
  /// iterando sobre eles, travando o jogo. Por isso só marcAbilityTarget.plrDira a intenção
  /// aqui; `update()` (que roda ANTES da varredura de colisão de cada
  /// frame — mesma ordem que o fix da grama alta já explorou) dispara
  /// `_evoluir()` de verdade um frame depois, fora da varredura.
  bool _evoluirPendente = false;

  void ganharXp(double quantidade) {
    if (evoluida || creatureData.evoluir == null) return;
    xp += quantidade;
    if (xp >= xpParaEvoluir) _evoluirPendente = true;
  }

  /// Troca o sprite e a `ability2` pra forma evoluída — DIFERENTE de
  /// `trocarCriatura`: aqui é a MESMA criatura ficando mais forte, então vida,
  /// escudo, cooldowns e multiplicadores de upgrade da run continuam
  /// exatamente como estavam (só `trocarCriatura`, que troca pra uma criatura
  /// DIFERENTE do banco, reseta esse estado de combate).
  void _evoluir() {
    final base = creatureData;
    final proxima = creatureData.evoluir!();
    creatureData = proxima;
    evoluida = true;
    xp = xpParaEvoluir;

    final jogo = game;
    if (jogo is CreaturesRogueGame) {
      jogo.companionCreatures[jogo.companionAtivoIndex] = proxima;
    }

    GameAudio.instance.play(Sfx.liberar);
    // Assíncrono, sem await — mesmo motivo de `trocarCriatura`: o cache de
    // sprite já foi aquecido em `_preloadCombatSprites`.
    _montarVisualEHitbox();

    // A troca de dado já aconteceu acima — isto só abre a cerimônia visual
    // por cima (pausa o jogo até o toque de continuar). Ver
    // `CreaturesRogueGame.mostrarEvolucao`/`EvolutionOverlay`.
    if (jogo is CreaturesRogueGame) {
      jogo.mostrarEvolucao(base, proxima);
    }
  }

  /// Estado "segurado" da habilidade 2 (o botão que sobrou) — dois canais
  /// independentes porque um vem do toque (`AbilityButton`, escreve direto)
  /// e o outro do teclado (recomputado a cada evento a partir de
  /// `keysPressed`, mesmo padrão de `_keyboardMove`). O disparo em si só
  /// acontece quando pelo menos um dos dois está true E o cooldown zerou —
  /// ver [_updateAbilities]. Habilidade 1 não tem mais canal "segurado":
  /// dispara direto pela direção do analógico/setas, ver
  /// [_direcaoAtaqueTravada].
  bool touchHoldAbility2 = false;
  bool _keyboardHoldAbility2 = false;

  bool naoMove = false;

  // Ganchos usados pelas habilidades das criaturas (shieldVisualActive,
  // speedLocked, shieldHits, damageReduction, refleteProjetil, retalia*)
  // vêm de AbilityUser.

  bool isAirborne = false;

  // --- Salto genérico (ex.: Jogada de Corpo) — mesma curva visual do
  // JumpMovement dos inimigos: sobe em arco e estica no ar. Enquanto
  // pulando, substitui o controle normal e o MovementAnimator (os dois
  // escrevem visual.position.y/scale, e disputariam o mesmo canal).
  bool _pulando = false;
  double _puloTimer = 0.0;
  double _puloDuracao = 0.3;
  double _puloAltura = 16.0;
  Vector2 _puloDirecao = Vector2.zero();
  double _puloVelocidade = 0.0;
  VoidCallback? _puloAoAterrissar;

  /// Salta na direção [direction], percorrendo [distance] px ao longo de
  /// [duration]s. Com [direction] zero (sem mira/movimento), pula no lugar
  /// — mesma curva de altura, sem deslocamento horizontal. [onLand] roda no
  /// frame em que os pés tocam o chão.
  void startJump({
    required Vector2 direction,
    required double distance,
    required double duration,
    double height = 16.0,
    VoidCallback? onLand,
  }) {
    _pulando = true;
    _puloTimer = 0.0;
    _puloDuracao = duration;
    _puloAltura = height;
    _puloAoAterrissar = onLand;
    velocity.setZero();

    if (direction.length == 0) {
      // Pulo vertical: sobe e desce no lugar, mantendo a direção que já
      // estava olhando.
      _puloDirecao = Vector2.zero();
      _puloVelocidade = 0.0;
      return;
    }

    _puloDirecao = direction.normalized();
    _puloVelocidade = distance / duration;

    if (_puloDirecao.x < 0 && !visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    } else if (_puloDirecao.x > 0 && visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    }
  }

  void _updateJump(double dt) {
    _puloTimer += dt;
    position += _puloDirecao * _puloVelocidade * dt;

    final progress = (_puloTimer / _puloDuracao).clamp(0.0, 1.0);
    final zOffset = 4 * _puloAltura * progress * (1 - progress);
    visual.position.y = _visualBasePosition.y - zOffset;

    final flip = visual.scale.x.isNegative ? -1.0 : 1.0;
    visual.scale = Vector2(0.9 * flip, 1.1); // estica no ar, igual ao inimigo

    if (_puloTimer >= _puloDuracao) {
      _pulando = false;
      visual.position.y = _visualBasePosition.y;
      visual.scale = Vector2(flip, 1.0);
      final aoAterrissar = _puloAoAterrissar;
      _puloAoAterrissar = null;
      aoAterrissar?.call();
    }
  }

  /// Reaplicar renova a duração e fica com o fator mais forte — nunca
  /// multiplica um sobre o outro, senão duas nuvens seguidas travam o jogador.
  /// Timer de [grantStatusImmunity] — enquanto > 0, `aplicarLentidao`,
  /// `aplicarCegueira` e `applyKnockback` viram no-op. NÃO cobre dano: golpe
  /// ainda chega normal em `takeDamage`.
  double _statusImunidadeTimer = 0.0;

  void aplicarLentidao(double duracao, {double fator = 0.5}) {
    if (_statusImunidadeTimer > 0) return;
    if (duracao > lentidaoTimer) lentidaoTimer = duracao;
    if (fator < lentidaoFator) lentidaoFator = fator;
  }

  void aplicarCegueira(double duracao) {
    if (_statusImunidadeTimer > 0) return;
    if (duracao <= cegoTimer) return;
    cegoTimer = duracao;
    cegoDuracaoInicial = duracao;
  }

  void grantInvulnerability(double seconds) {
    if (seconds > _invulnerabilityTimer) _invulnerabilityTimer = seconds;
  }

  void grantStatusImmunity(double seconds) {
    if (seconds > _statusImunidadeTimer) _statusImunidadeTimer = seconds;
  }

  /// Ação pessoal do jogador — não passa por `Ability` nenhuma. Mesma receita
  /// de `EsquivaBomba`: i-frames curtos mais um dash curto com rastro
  /// fantasma.
  double _dodgeCooldown = 0.0;
  static const double _dodgeCooldownMax = 1.1;
  static const double _dodgeDuration = 0.18;
  static const double _dodgeDistance = 30.0;

  /// Duração dos i-frames da esquiva, exposta pra fora — algumas passivas
  /// (ex.: Casco Reflexivo, Rastro Flamejante) agendam efeito pra terminar
  /// junto com a janela de invulnerabilidade, sem duplicar o número aqui.
  double get dodgeIframeDuration => _dodgeDuration;

  /// Passivas das criaturas do grupo (ver `Passive`) — vale enquanto a
  /// criatura estiver no grupo, ativa ou no banco. Por isso lê
  /// `companionCreatures` (sobrevive ao banco), não só a ativa. Sempre
  /// recomputado no uso, nunca cacheado — elimina qualquer ponto de
  /// recálculo que precisaria ser lembrado em recrutamento/troca/início de
  /// run.
  ///
  /*
  List<Passive> get passivasAtivas {
    final jogo = game;
    if (jogo is! CreaturesRogueGame) return const [];
    return jogo.companionCreatures
        .whereType<CreatureData>()
        .map((c) => c.passive)
        .toList(growable: false);
  }
  */
  /// Piso do produto de `dodgeCooldownMult` de todas as passivas ativas —
  /// pedido do usuário: passiva repetida (duas ou três criaturas da mesma
  /// espécie) DEVE empilhar, é build válido. Mas sem piso, três cópias de
  /// `ReflexoEletrico` (0.6 cada) dão `0.6³ ≈ 0.22`, ou seja `_dodgeCooldownMax`
  /// (1.1s) vira ~0.24s — menor que a folga entre o fim de uma esquiva e o
  /// início da próxima ser maior que a duração dos i-frames (0.18s), o que
  /// destrava esquiva encadeada = invulnerabilidade quase permanente. Isso
  /// não é "build forte", é o sistema de esquiva inteiro deixando de
  /// importar. 0.3 (30% do cooldown base, ~0.33s) deixa empilhar valer muito
  /// sem zerar a janela de risco. Só no cooldown: `dodgeDistanceMult` não
  /// tem essa classe de risco (não cria invulnerabilidade), fica sem piso.
  static const double _dodgeCooldownMultFloor = 0.3;

  void dodge() {
    if (_dodgeCooldown > 0) return;
    GameAudio.instance.play(Sfx.dash);
    //final passivas = passivasAtivas;

    double cooldownMult = 1.0;
    double distanciaMult = 1.0;
    /* for (final p in passivas) {
      cooldownMult *= p.dodgeCooldownMult;
      distanciaMult *= p.dodgeDistanceMult;
    }
    */
    cooldownMult = cooldownMult < _dodgeCooldownMultFloor
        ? _dodgeCooldownMultFloor
        : cooldownMult;
    _dodgeCooldown = _dodgeCooldownMax * cooldownMult;
    grantInvulnerability(_dodgeDuration);

    var dir = velocity.isZero() ? plrDir : velocity.normalized();
    /*for (final p in passivas) {
      final override = p.direcaoEsquivaOverride(this, dir);
      if (override != null) dir = override;
    }
    */
    GhostEffect.spawnTrail(
      visual: visual,
      add: (g) => parent?.add(g),
      overDuration: _dodgeDuration,
    );
    add(
      MoveByEffect(
        dir * _dodgeDistance * distanciaMult,
        EffectController(duration: _dodgeDuration),
      ),
    );
    /*
    for (final p in passivas) {
      p.aoEsquivar(this, dir);
    }
    */
  }

  /// Fração restante do cooldown da esquiva (0 = pronta) — pra HUD desenhar
  /// um indicador, se algum dia precisar de um terceiro.
  double get dodgeCooldownFraction =>
      (_dodgeCooldown / _dodgeCooldownMax).clamp(0.0, 1.0);

  // --- Indicador da esquiva, embaixo do sprite ---
  // Barra que ENCHE conforme a esquiva recarrega (vazia assim que usa, cheia
  // quando pronta) — oposto do indicador de habilidade da Hud, que ESVAZIA um
  // cinza por cima do ícone. Não tem ícone aqui pra esvaziar, é só uma cor.
  //static final Paint _dodgeBarraMoldura = Paint()..color = Palette.preto;
  //static final Paint _dodgeBarraFundo = Paint()..color = Palette.cinzaEsc;
  //static final Paint _dodgeBarraPreenchimento = Paint()..color = Palette.verde;
  //static const double _dodgeBarraLargura = 14.0;
  //static const double _dodgeBarraAltura = 2.0;

  /// Não é `final`: `_montarVisualEHitboxInterno` reatribui a cada remontagem
  /// (troca de criatura, evolução). Com `late final` a segunda remontagem já
  /// jogava `LateInitializationError` (campo `final` só aceita UMA
  /// atribuição na vida do objeto) — o erro ficava escondido porque a
  /// função é assíncrona e sem `await` no chamador (ver `_montarVisualEHitbox`).
  late ConditionIcons conditionIcons;

  /// Anéis de cooldown das duas habilidades, guardados aqui só pra poder
  /// remover o antigo antes de recriar a cada remontagem — sem isso, cada
  /// troca de criatura ou evolução deixava um par órfão pra trás.
  CooldownRingIndicator? _ringAbility1;
  CooldownRingIndicator? _ringAbility2;
  /*
  void _renderBarraEsquiva(Canvas canvas) {
    final pronto = 1 - dodgeCooldownFraction;
    final left = (size.x - _dodgeBarraLargura) / 2;
    final top = size.y + 4.0;

    canvas.drawRect(
      Rect.fromLTWH(left - 1, top - 1, _dodgeBarraLargura + 2, _dodgeBarraAltura + 2),
      _dodgeBarraMoldura,
    );
    canvas.drawRect(Rect.fromLTWH(left, top, _dodgeBarraLargura, _dodgeBarraAltura), _dodgeBarraFundo);
    if (pronto > 0) {
      canvas.drawRect(
        Rect.fromLTWH(left, top, _dodgeBarraLargura * pronto, _dodgeBarraAltura),
        _dodgeBarraPreenchimento,
      );
    }
  }
*/
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (shieldVisualActive) {
      for (var i = 0; i < shieldHits; i++) {
        canvas.drawCircle(
          Offset(-4, i * 6 + 4),
          2.0,
          Paint()
            ..color = creatureData.corClara
            ..filterQuality = FilterQuality.none,
        );
        canvas.drawCircle(
          Offset(-4, i * 6 + 4),
          2.0,
          Paint()
            ..color = creatureData.corEscura
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..filterQuality = FilterQuality.none,
        );
      }
    }
  }

  Player({
    required this.moveJoystick,
    required this.aimJoystick,
    required this.creatureData,
  }) : maxHealth = creatureData.stats.maxHp,
       currentHealth = creatureData.stats.maxHp,
       shieldMax = creatureData.stats.shieldMax,
       shield = creatureData.stats.shieldMax,
       super(size: Vector2(16, 16), anchor: Anchor.center) {
    // Um Player novo é exatamente uma run nova (ver `startRun`), então este é
    // o lugar certo pra zerar o multiplicador estático de dano — senão os
    // upgrades da run anterior valeriam na próxima.
    danoMult = 1.0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _montarVisualEHitbox();

    final ui.Image circDirImg = await Flame.images.load('actors/circDir.png');
    circDir = SpriteComponent(
      sprite: Sprite(circDirImg),
      size: Vector2.all(24),
      anchor: Anchor.center,
      position: _visualBasePosition,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: -2,
    );
    add(circDir);
  }

  /// Monta sprite, escudo, hitboxes e sombra a partir de `creatureData`.
  /// Chamado uma vez em `onLoad` e de novo em `trocarCriatura` — nesse
  /// segundo caso remove os componentes antigos primeiro (`_visualPronto`
  /// distingue os dois casos: no `onLoad` não há nada pra remover ainda).
  /// Assíncrono porque o sprite passa por `PaletteSwapper`, mas já vem do
  /// cache aquecido por `_preloadCombatSprites` — sem travadinha perceptível
  /// mesmo trocando em pleno combate.
  /// Guarda contra uma segunda chamada pousar enquanto a primeira ainda
  /// espera o `PaletteSwapper` — sem isso, a que chega por último acha
  /// `_visualPronto` ainda falso (só vira `true` no fim desta função) e
  /// pula a remoção dos componentes antigos, e as duas completam
  /// adicionando visual/hitbox duplicados.
  bool _montando = false;

  Future<void> _montarVisualEHitbox() async {
    if (_montando) return;
    _montando = true;
    try {
      if (_visualPronto) {
        visual.removeFromParent();
        shieldVisual.removeFromParent();
        playerHitbox.removeFromParent();
        physicsHitbox.removeFromParent();
        shadow.removeFromParent();
        conditionIcons.removeFromParent();
        _ringAbility1?.removeFromParent();
        _ringAbility2?.removeFromParent();
      }

      await _montarVisualEHitboxInterno();
    } finally {
      _montando = false;
    }
  }

  Future<void> _montarVisualEHitboxInterno() async {
    final ui.Image spriteImage = await PaletteSwapper.createSwappedImage(
      imagePath: creatureData.spritePath,
      lightGrayReplacement: creatureData.corClara,
      darkGrayReplacement: creatureData.corEscura,
    );

    _visualBasePosition = Vector2(size.x / 2, size.y);
    _moveAnimator = MovementAnimator(creatureData.moveAnim);

    visual = SpriteComponent(
      sprite: Sprite(spriteImage),
      // `spriteSize` (ver CreatureData) deixa a arte evoluída em 24x24 sem
      // mexer no hitbox — `size` (o `Vector2(16,16)` fixo do Player) continua
      // sendo a referência de tudo mais (hitbox, sombra, posição da UI).
      size: creatureData.spriteSize ?? size,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition.clone(),
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 1,
    );
    add(visual);

    Vector2 floatOffset = Vector2.zero();
    Vector2 evoOff = evoluida ? Vector2(0, -8) : Vector2.zero();

    conditionIcons = ConditionIcons()
      ..position = Vector2(size.x / 2, -6 + evoOff.y);
    add(conditionIcons);

    if (creatureData.moveAnim == MovementAnimation.flutuar) {
      isAirborne = true;
      floatOffset = Vector2(0, -4);
    } else {
      isAirborne = false;
    }

    _ringAbility1 = CooldownRingIndicator(
      tipo: () => creatureData.ability1.tipo,
      cooldownFraction: () => ability1CooldownFraction,
      raio: 4,
      position: Vector2(4, -4 + floatOffset.y + evoOff.y),
    )..priority = 2;
    add(_ringAbility1!);

    _ringAbility2 = CooldownRingIndicator(
      tipo: () => creatureData.ability2.tipo,
      cooldownFraction: () => ability2CooldownFraction,
      raio: 4,
      position: Vector2(12, -4 + floatOffset.y + evoOff.y),
    )..priority = 2;
    add(_ringAbility2!);

    final ui.Image shieldImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'projeteis/bolha.png',
      lightGrayReplacement: creatureData.corClara,
      darkGrayReplacement: creatureData.corEscura,
      whiteReplacement: Palette.branco,
    );
    shieldVisual = SpriteComponent(
      sprite: Sprite(shieldImage),
      size: Vector2.all(24),
      anchor: Anchor.center,
      position: size / 2 + floatOffset,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 5,
    );
    shieldVisual.setOpacity(0.0); // só aparece enquanto shieldVisualActive
    add(shieldVisual);

    final hitboxSize = creatureData.hitboxSize;
    playerHitbox = RectangleHitbox(
      size: hitboxSize,
      anchor: Anchor.bottomCenter,
      position: _visualBasePosition + floatOffset,
      collisionType: CollisionType.active,
    );
    add(playerHitbox);

    physicsHitbox = RectangleHitbox(
      size: Vector2(hitboxSize.x, hitboxSize.x * 0.5),
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, hitboxSize.y / 2),
      collisionType: CollisionType.active,
    );
    add(physicsHitbox);

    shadow = CircleComponent(
      radius: hitboxSize.x / 2,
      anchor: Anchor.center,
      position: _visualBasePosition,
      paint: Paint()..color = Palette.preto,
      priority: -1,
    )..scale = Vector2(1.2, 0.75);
    add(shadow);

    _visualPronto = true;
  }

  /// Troca a criatura ativa em pleno jogo (PIVOT_CONTROLE_DIRETO.md §2.3) —
  /// chamado por `CreaturesRogueGame` quando o jogador toca um retrato do
  /// banco disponível, ou quando a vida zera e o jogo troca sozinho.
  ///
  /// Muta esta instância em vez de recriar o componente: `RoomComponent`
  /// guarda `player:` como campo `final` no construtor, e toda sala já
  /// gerada na run aponta pra esta instância — recriar deixaria elas com uma
  /// referência morta.
  ///
  /// Estado de combate não atravessa a troca (cooldowns, escudo de
  /// habilidade, buffs, knockback) — só a vida salva do banco. A criatura que
  /// entra recebe o escudo passivo cheio, não o que a anterior tinha quando
  /// saiu (o banco só guarda HP, não escudo). XP e evolução (ver
  /// `PIVOT_EVOLUCAO`) são a exceção: cada slot guarda o próprio progresso, e
  /// [xpSalvo]/[evoluidaSalva] restauram o do slot que está entrando.
  void trocarCriatura(
    CreatureData nova, {
    required double vidaSalva,
    double xpSalvo = 0.0,
    bool evoluidaSalva = false,
  }) {
    creatureData = nova;
    maxHealth = nova.stats.maxHp;
    currentHealth = vidaSalva.clamp(0.0, maxHealth);
    xp = xpSalvo;
    evoluida = evoluidaSalva;
    shieldMax = nova.stats.shieldMax;
    shield = shieldMax;
    shieldHits = 0;
    shieldVisualActive = false;
    damageReduction = 0.0;
    speedLocked = false;
    refleteProjetil = false;
    retaliaEspinhos = false;
    retaliaDano = 0.0;
    retaliaStunDuration = 0.0;
    knockbackVelocity = Vector2.zero();
    _cooldown1 = 0.0;
    _cooldown2 = 0.0;
    cdMult = 1.0;
    _dodgeCooldown = 0.0;
    velocity.setZero();

    // Assíncrono, sem await: o cache de sprite já está aquecido (mesma
    // chave que `_preloadCombatSprites` monta pra toda criatura do
    // registro), então o resultado chega praticamente no frame seguinte.
    _montarVisualEHitbox();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Fora da varredura de colisão de propósito — ver comentário de
    // `ganharXp`/`_evoluirPendente`.
    if (_evoluirPendente) {
      _evoluirPendente = false;
      _evoluir();
    }

    // Anchor.center: o "chão" (pés) fica meio size.y abaixo do centro.
    priority = ySortPriority(position.y + size.y / 2);

    conditionIcons.lentidaoAtivo = _gramaAltaSobrepostas.isNotEmpty;

    if (_dodgeCooldown > 0) _dodgeCooldown -= dt;
    _tempoSemApanhar += dt;
    // for (final p in passivasAtivas) {
    //   p.aoAtualizar(this, dt);
    // }

    if (lentidaoTimer > 0) {
      lentidaoTimer -= dt;
      if (lentidaoTimer <= 0) lentidaoFator = 1.0;
    }
    if (cegoTimer > 0) cegoTimer -= dt;

    Vector2 moveDelta = moveJoystick.relativeDelta.clone();
    if (moveDelta.isZero() && !_keyboardMove.isZero()) {
      moveDelta = _keyboardMove.normalized();
    }

    if (_invulnerabilityTimer > 0) {
      _invulnerabilityTimer -= dt;
      bool isVisible = (_invulnerabilityTimer * 10).toInt() % 2 == 0;
      visual.setOpacity(isVisible ? 1.0 : 0.2);
    } else {
      visual.setOpacity(1.0);
    }

    if (_statusImunidadeTimer > 0) _statusImunidadeTimer -= dt;

    shieldVisual.setOpacity(shieldVisualActive ? 1.0 : 0.0);

    if (shield <= shieldMax) {
      _shieldRegenTimer += dt;
      if (_shieldRegenTimer >= shieldRegenInterval) {
        _shieldRegenTimer = 0.0;
        shield = (shield + shieldRegenAmount).clamp(0.0, shieldMax);
      }
    }

    if (_pulando) {
      _updateJump(dt);
    } else {
      _updateMovement(dt, moveDelta);

      _moveAnimator.update(
        visual: visual,
        basePosition: _visualBasePosition,
        isMoving: !velocity.isZero(),
        horizontalDir: velocity.isZero() ? 0.0 : velocity.normalized().x,
        dt: dt,
      );
    }

    _updateAbilities(dt);
  }

  /// Inimigo mais próximo na sala atual — usada pela mira travada
  /// (`AbilityTarget.enemyDir`), mesma restrição por sala que os itens de
  /// área (congelar, etc.) já usam.
  Enemy? _nearestEnemy() {
    final room = currentRoom;
    final enemies = parent?.children.whereType<Enemy>() ?? const <Enemy>[];

    Enemy? nearest;
    double nearestDistSq = double.infinity;
    for (final enemy in enemies) {
      if (enemy.pulando) continue;
      if (room != null &&
          !room.toAbsoluteRect().contains(
            Offset(enemy.absolutePosition.x, enemy.absolutePosition.y),
          )) {
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

  /// Só a habilidade 2 mira sozinha agora — a 1 é sempre o jogador quem
  /// aponta (ver [_direcaoAtaqueTravada]).
  void _atualizarMira() {
    final alvo = _nearestEnemy();
   
    if (creatureData.ability2.target == AbilityTarget.enemyDir) {
      if (alvo != null) {
        final delta = alvo.absolutePosition - absolutePosition;
        if (delta.length != 0) lockedAb2Direction = delta.normalized();
      }
    } else if (creatureData.ability2.target == AbilityTarget.plrDir) {
      lockedAb2Direction = plrDir;
    }
  }

  /// Zona morta do analógico de ataque — abaixo disso conta como "solto",
  /// senão um toque leve/trêmulo dispararia a habilidade 1 sem intenção.
  static const double _zonaMortaAtaque = 0.35;

  /// Direção travada (só as 4 cardeais — trava no eixo de maior
  /// deslocamento) do analógico direito ou das setas do teclado.
  /// `Vector2.zero()` quando nenhum dos dois está empurrado além da zona
  /// morta — nesse caso a habilidade 1 simplesmente não dispara neste
  /// frame (ver [_updateAbilities]).
  Vector2 _direcaoAtaqueTravada() {
    var bruto = aimJoystick.relativeDelta;
    if (bruto.length2 < _zonaMortaAtaque * _zonaMortaAtaque) {
      bruto = Vector2.zero();
    }
    if (bruto.isZero() && !_keyboardAtaqueDir.isZero()) {
      bruto = _keyboardAtaqueDir;
    }
    if (bruto.isZero()) return Vector2.zero();

    return bruto.x.abs() >= bruto.y.abs()
        ? Vector2(bruto.x.sign, 0)
        : Vector2(0, bruto.y.sign);
  }

  /// Dispara `ability1`/`ability2` se o cooldown já zerou.
  void dispararAbility1() {
    if (_cooldown1 > 0) return;
    if (!creatureData.ability1.canExecute(this)) return;
    creatureData.ability1.execute(this, lockedAb1Direction);
    _cooldownMax1 = creatureData.ability1.cooldown * cdMult;
    _cooldown1 = _cooldownMax1;
  }

  void dispararAbility2() {
    if (_cooldown2 > 0) return;
    if (!creatureData.ability2.canExecute(this)) return;
    creatureData.ability2.execute(this, lockedAb2Direction);
    _cooldownMax2 = creatureData.ability2.cooldown * cdMult;
    _cooldown2 = _cooldownMax2;
  }

  /// Habilidade 1: twin-stick de eixos travados — dispara sozinha, na
  /// direção travada, enquanto o analógico/setas estiver fora da zona
  /// morta. Habilidade 2: continua um botão/tecla "segurada", mesmo padrão
  /// que a IA autônoma do companion já usava (ver PIVOT_TREINADOR.md).
  void _updateAbilities(double dt) {
    if (_cooldown1 > 0) _cooldown1 -= dt;
    if (_cooldown2 > 0) _cooldown2 -= dt;

    _atualizarMira();

    final direcaoAtaque = _direcaoAtaqueTravada();
    if (!direcaoAtaque.isZero()) {
      lockedAb1Direction = direcaoAtaque;
      dispararAbility1();
    }

    if (touchHoldAbility2 || _keyboardHoldAbility2) dispararAbility2();
  }

  /// Sala onde o player está agora (mesma lógica usada por `Enemy.currentRoom`).
  RoomComponent? get currentRoom {
    final p = parent;
    if (p == null) return null;
    final center = Offset(absolutePosition.x, absolutePosition.y);
    for (final room in p.children.whereType<RoomComponent>()) {
      if (room.toAbsoluteRect().contains(center)) return room;
    }
    return null;
  }

  @override
  Vector2 dashOffsetLivre(Vector2 dir, double distancia) {
    final d = dir.normalized();
    if (d.isZero() || distancia <= 0) return Vector2.zero();

    final room = currentRoom;
    if (room == null) return d * distancia;

    // Mesma regra sólida do `onCollision`: GramaAlta/Cogumelos são andáveis
    // (nunca sólidos), Hole só bloqueia fora do ar. Pro resto dos `Obstacle`
    // (Rock, Door, Pedestal...) usa o `collisionType` AO VIVO do hitbox —
    // Grama/ChaoCave são decoração de chão (`CollisionType.inactive`, nunca
    // colidem de verdade) e Door alterna passive/inactive ao abrir/fechar, e
    // seu campo `collisionType` (fixo, só reflete o valor da construção) não
    // acompanha isso — só o `hitbox.collisionType` está sempre atualizado.
    final solidos = room.children.whereType<PositionComponent>().where((c) {
      if (c is WallBarrier) return true;
      if (c is GramaAlta || c is Cogumelos) return false;
      if (c is Hole) return !isAirborne;
      if (c is Obstacle) return c.hitbox.collisionType != CollisionType.inactive;
      return false;
    });

    // Anda em passos de 4px (bem menor que os 16px de um tile) simulando o
    // `physicsHitbox`, pra achar o ponto mais longe livre antes da parede —
    // `MoveByEffect` move a posição direto, sem checar colisão a cada frame.
    const passo = 4.0;
    final pesBase = physicsHitbox.toAbsoluteRect();
    final passos = (distancia / passo).ceil();
    var livre = 0.0;
    for (var i = 1; i <= passos; i++) {
      final p = i < passos ? i * passo : distancia;
      final testRect = pesBase.shift(ui.Offset(d.x * p, d.y * p));
      if (solidos.any((s) => s.toAbsoluteRect().overlaps(testRect))) break;
      livre = p;
    }
    return d * livre;
  }

  /// Empurra o jogador para longe de [sourcePosition]. Usado por explosões
  /// de inimigos que repelem (Brado, bote da Cobra).
  void applyKnockback(Vector2 sourcePosition, double force) {
    if (_statusImunidadeTimer > 0) return;
    final direction = (absolutePosition - sourcePosition);
    if (direction.length == 0) return;
    knockbackVelocity = direction.normalized() * force;
  }

  void _updateMovement(double dt, Vector2 moveDelta) {
    // Knockback tem prioridade sobre o controle: enquanto empurrado, o
    // jogador desliza e o input não responde (mesma regra do inimigo).
    if (!knockbackVelocity.isZero()) {
      position += knockbackVelocity * dt;

      final drop = 240.0 * dt; // atrito
      if (knockbackVelocity.length < drop) {
        knockbackVelocity.setZero();
      } else {
        knockbackVelocity -= knockbackVelocity.normalized() * drop;
      }
      velocity.setZero();
      return;
    }

    if (naoMove || speedLocked) {
      velocity.setZero();
      return;
    }
    if (!moveDelta.isZero()) {
      //velocity += moveDelta * acceleration * dt;
      plrDir = moveDelta;
      circDir.angle = plrDir.screenAngle();
      velocity = moveDelta * maxSpeed;
      //if (velocity.length > maxSpeed) {
      //  velocity = velocity.normalized() * maxSpeed;
      //}
    } else {
      if (!velocity.isZero()) {
        double drop = friction * dt;

        if (velocity.length < drop) {
          velocity.setZero();
        } else {
          velocity -= velocity.normalized() * drop;
        }
      }
    }

    if (velocity.isZero()) return;

    position += velocity * dt;

    if (velocity.x < 0 && !visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && visual.isFlippedHorizontally) {
      visual.flipHorizontallyAroundCenter();
    }
  }

  // --- NOVA FUNÇÃO DE VALIDAÇÃO DE COLISÃO ---
  bool isPhysicsCollision(PositionComponent other) {
    // Se no futuro você adicionar uma mecânica de ROLAR (Dodge/Dash) para o player
    // e criar uma variável "isAirborne", você também pode ignorar obstáculos aqui!

    if (!physicsHitbox.toAbsoluteRect().overlaps(other.toAbsoluteRect())) {
      return false;
    }
    return true;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Só entra no set quando os PÉS confirmam sobreposição neste instante —
    // com `playerHitbox` (corpo) maior que `physicsHitbox` (pés) e centrado
    // no mesmo ponto, o corpo costuma encostar na grama um pouco antes dos
    // pés. Ignorar esse `Start` prematuro (disparado pelo par
    // `playerHitbox`) e deixar o `Start` do par `physicsHitbox` (que já vem
    // com os pés confirmados) fazer o `add` de verdade.
    if (other is GramaAlta && isPhysicsCollision(other) && !isAirborne) {
      _gramaAltaSobrepostas.add(other);
    }

    if (other is Cogumelos && isPhysicsCollision(other) && !isAirborne) {
      _cogumelosSobrepostos.add(other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    // Espelha o `Start`: só tira do set quando os pés já NÃO sobrepõem mais
    // — assim o fim do par `playerHitbox` (corpo saindo, pés ainda dentro)
    // não desliga o efeito cedo demais.
    if (other is GramaAlta && !isPhysicsCollision(other)) {
      _gramaAltaSobrepostas.remove(other);
    }

    if (other is Cogumelos && !isPhysicsCollision(other)) {
      _cogumelosSobrepostos.remove(other);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Enemy) {
      // O Inimigo só nos causa dano se o corpo dele bater no nosso corpo!
      if (other.enemyHitbox.toAbsoluteRect().overlaps(
        playerHitbox.toAbsoluteRect(),
      )) {
        takeDamage(1, other.creature!.tipo);
      }
    }

    // Grama alta: terreno andável, não parede. `return` antes do bloco de
    // empurrão abaixo, senão `GramaAlta` (que é um `Obstacle` como
    // qualquer outro) seria tratada como sólida — o efeito de velocidade em
    // si é todo tratado em `onCollisionStart`/`onCollisionEnd`, não aqui.
    if (other is GramaAlta || other is Cogumelos) return;

    if (other is WallBarrier || other is Obstacle) {
      // MÁGICA AQUI: Só para de andar se bater os pés (sombra)!
      if (!isPhysicsCollision(other) || (isAirborne && other is Hole)) return;

      // Empurra pela profundidade real do overlap. O rect é lido AGORA, não no
      // começo do frame: numa quina chegam duas chamadas de onCollision no
      // mesmo frame, e a segunda precisa ver a correção que a primeira fez.
      final empurrao = empurraoParaFora(
        corpo: physicsHitbox.toAbsoluteRect(),
        alvo: other.toAbsoluteRect(),
      );
      if (empurrao.isZero()) return;

      position += empurrao;

      // Zera a velocidade só no eixo empurrado — o outro eixo continua, e é
      // isso que permite deslizar rente à parede em vez de parar de vez.
      if (empurrao.x != 0) velocity.x = 0;
      if (empurrao.y != 0) velocity.y = 0;
    }
  }

  void takeDamage(double amount, CreatureType tipoAtacante) {
    if (_invulnerabilityTimer > 0) return;

    final mult = typeMultiplier(tipoAtacante, creatureData.tipo);
    Color corTxt = Palette.amarelo;
    if (mult > 1.0) {
      corTxt = Palette.vermelho;
    } else if (mult < 1.0) {
      //fontSize = 4;
      corTxt = Palette.cinza;
    }

    double amountFinal = mult * amount * (1 - damageReduction);
    if (amountFinal <= 0)
      return; // golpe totalmente mitigado: não gasta i-frame
    GameAudio.instance.play(Sfx.hit);

    _invulnerabilityTimer = _invulnerabilityDuration;
    _tempoSemApanhar = 0.0;

    // Passivas de retaliação (ex.: Retaliação Elétrica do Ouriço) — ANTES de
    // qualquer escudo, de forma que disparem sempre que o jogador tenta
    // tomar dano, mesmo que o golpe seja inteiramente absorvido pelo escudo
    // logo abaixo. Se o grupo tiver mais de uma criatura com retaliação,
    // todas executam — decisão travada com o usuário, não é "a mais forte
    // vence" (ver PIVOT_TREINADOR.md).
    //for (final p in passivasAtivas) {
    //  p.aoTentarTomarDano(this, amountFinal);
    //}

    parent?.add(
      TextEffect.dano(
        amountFinal,
        position: position.clone() + Vector2(0, -size.y / 2 - 4),
        color: corTxt,
      ),
    );

    if (shieldHits > 0) {
      shieldHits--;
      if (shieldHits <= 0) shieldVisualActive = false; // a bolha estourou
      return;
    }

    // Escudo passivo (defesa) absorve antes do HP — segunda barra, não a
    // bolha de habilidade (shieldHits), que já retornou acima se ativa.
    //
    // O excedente PASSA pro HP. Antes o escudo comia o golpe inteiro e jogava
    // o resto fora, então 1 ponto de escudo anulava um golpe de 10 do boss —
    // qualquer item de escudo ficava absurdo.
    if (shield > 0) {
      //final absorvido = amountFinal > shield ? shield : amountFinal;
      shield -= 1;
      //amountFinal -= absorvido;
      if (shield < 0) shield = 0;
      return; // o golpe foi absorvido pelo escudo, não chega no HP
      // Sem arredondar o resto pra cima: com 0.5 de escudo sobrando, um
      // arredondamento faria o golpe de 1 (contato de inimigo) chegar inteiro
      // no HP, ou seja, o último ponto fracionado de escudo sairia de graça pro
      // atacante. A barra da Hud escala contínuo, então HP fracionado desenha
      // bem.
      //if (amountFinal <= 0) return;
    }

    currentHealth -= amountFinal;

    if (currentHealth <= 0) {
      final jogo = game;
      if (jogo is CreaturesRogueGame) jogo.pocketarSlotAtivo();
    }
  }

  @override
  void placeBomb(Vector2 dir) {
    //if (bombsAmount <= 0) return;
    //bombsAmount--;
    parent?.add(Bomb(position: position.clone() + (dir * 17)));
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // WASD = movimento (equivalente ao analógico esquerdo).
    _keyboardMove.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) _keyboardMove.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) _keyboardMove.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) _keyboardMove.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) _keyboardMove.y += 1;

    // Setas = direção do ataque (habilidade 1, equivalente ao analógico
    // direito — ver `_direcaoAtaqueTravada`). Espaço = habilidade 2,
    // segurada (mesmo padrão do botão de toque).
    _keyboardAtaqueDir.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft))
      _keyboardAtaqueDir.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight))
      _keyboardAtaqueDir.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp))
      _keyboardAtaqueDir.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown))
      _keyboardAtaqueDir.y += 1;
    _keyboardHoldAbility2 = keysPressed.contains(LogicalKeyboardKey.space);

    // Teclas 1 e 2 = os dois slots do inventário, equivalente a clicar neles.
    // Só no KeyDownEvent: o teclado repete a tecla segurada, e com isso o
    // segundo item entraria e sairia do slot no mesmo aperto.
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) useSlot(0);
      if (event.logicalKey == LogicalKeyboardKey.digit2) useSlot(1);
    }

    return super.onKeyEvent(event, keysPressed);
  }

  bool heal(int amount) {
    if (currentHealth < maxHealth) {
      currentHealth += amount;
      if (currentHealth > maxHealth) currentHealth = maxHealth;
      return true;
    }
    return false;
  }

  void addBomb(int amount) {
    bombsAmount += amount;

    if (bombsAmount > 99) bombsAmount = 99;
  }

  void addCoins(int amount) {
    coins += amount;
  }

  /// Guarda [tipo] no primeiro slot livre. Retorna false com os dois cheios —
  /// e é esse false que faz o item continuar no chão (ver
  /// `Collectible.onCollect`), em vez de sumir sem efeito.
  bool addConsumable(ConsumableType tipo) {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) {
        slots[i] = tipo;
        return true;
      }
    }
    return false;
  }

  /// Gasta o item do slot [index]. Slot vazio é no-op, não erro: o botão da
  /// tela existe sempre, cheio ou não.
  ///
  /// O slot só é limpo se o efeito teve serventia (ver `ConsumableType.aplicar`)
  /// — poção com vida cheia, ou mapa dentro de sala trancada, não gastam o item.
  void useSlot(int index) {
    if (index < 0 || index >= slots.length) return;
    final tipo = slots[index];
    if (tipo == null) return;

    if (tipo.aplicar(this)) slots[index] = null;
  }

  /// Marca todas as salas do andar como reveladas (item Mapa). Só mexe no
  /// minimapa: `isRevealed` é separado de `isVisited` justamente pra revelar
  /// não destrancar sala nenhuma nem abrir porta (ver RoomData).
  ///
  /// Vale só pro andar atual — `nextLevel` gera RoomData novo, com o campo de
  /// volta em false, então não há o que resetar aqui.
  ///
  /// Devolve false, sem revelar nada, dentro de sala trancada: o minimapa se
  /// esconde por completo enquanto a sala não está limpa (ver
  /// `MinimapHud.render`), então usar o mapa ali gastaria o item pra não mostrar
  /// coisa nenhuma.
  bool revelarMapa() {
    final jogo = game;
    if (jogo is! CreaturesRogueGame) return false;

    final salaAtual = currentRoom?.data;
    if (salaAtual != null &&
        !salaAtual.isCleared &&
        salaAtual.type != RoomType.start) {
      return false;
    }

    for (final sala in jogo.mapData.values) {
      sala.isRevealed = true;
    }
    return true;
  }

  /// Atordoa todo inimigo da sala atual (item Congelar). Restringe à sala pelo
  /// mesmo motivo da mira automática: todos os inimigos da dungeon existem ao
  /// mesmo tempo, então sem o filtro o item congelaria o andar inteiro.
  ///
  /// Devolve false quando não havia ninguém pra congelar — assim o item não é
  /// gasto num clique fora de combate.
  bool congelarInimigos(double duracao) {
    final room = currentRoom;
    final enemies = parent?.children.whereType<Enemy>() ?? const <Enemy>[];
    bool congelouAlgum = false;

    for (final enemy in enemies) {
      if (room != null &&
          !room.toAbsoluteRect().contains(
            Offset(enemy.absolutePosition.x, enemy.absolutePosition.y),
          )) {
        continue;
      }
      enemy.applyParalise(duracao);
      congelouAlgum = true;
    }

    return congelouAlgum;
  }
}
