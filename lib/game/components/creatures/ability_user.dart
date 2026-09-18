import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:creatures_rogue/game/components/effects/efeitos_temporarios.dart';
import 'creature_data.dart';

/// Contrato que uma habilidade (Ability) precisa de quem a executa. Tanto
/// `Player` quanto `Companion` (ver PIVOT_TREINADOR.md) usam este mixin — é o
/// que permite que a mesma instância stateless de `Ability` sirva à forma
/// jogável e à forma companion sem duplicar as 31 classes de habilidade.
///
/// `on PositionComponent` porque várias habilidades chamam `user.add(...)`,
/// leem `user.parent`/`user.position`/`user.size`/`user.isMounted` — membros
/// de `Component`/`PositionComponent` que não fazem sentido redeclarar aqui.
/// Energia máxima de partida de toda criatura — ver `AbilityUser.energiaMax`.
const double energiaMaxPadrao = 10.0;

/// Quanto de energia regenera por segundo (ver `Player._updateAbilities`).
const double energiaRegenPorSegundo = 5.0;

/// Quanto tempo a regeneração fica parada depois de cada uso da habilidade 1.
///
/// Sem isso a energia voltava DURANTE a rajada, então segurar o ataque rendia
/// mais tiros do que o custo por tiro sugere — a barra só limitava rajadas
/// muito longas. Com a pausa, o custo de cada tiro é pago de verdade antes de
/// qualquer recuperação.
const double energiaRegenAtraso = 0.3;

/// Uma carga da bolha, com a fonte que a pôs lá.
class _CargaEscudo {
  _CargaEscudo(this.chave, this.golpes);

  /// `null` = escudo sem prazo (o item consumível ESCUDO). Nunca expira
  /// sozinho e é sempre o ÚLTIMO a ser gasto.
  final Object? chave;
  int golpes;
}

mixin AbilityUser on PositionComponent, EfeitosTemporarios {
  CreatureData get creatureData;

  SpriteComponent get visual;

  /// Mira travada de cada botão: o inimigo mais próximo, ou a direção do
  /// movimento/corpo, conforme `Ability.target`. Cada `AbilityUser` calcula a
  /// própria (Player a partir de si mesmo; Companion a partir de si mesmo).
  Vector2 get lockedAb1Direction;
  Vector2 get lockedAb2Direction;

  /// Bombas são recurso do treinador (ver PIVOT_TREINADOR.md §3.2): mesmo
  /// quando quem executa é um Companion, `bombsAmount` e `placeBomb` sempre
  /// resolvem para o contador do treinador.
  int get bombsAmount;

  void placeBomb(Vector2 dir);

  void grantInvulnerability(double seconds);

  /// Janela de imunidade a STATUS (lentidão, cegueira, knockback) — DIFERENTE
  /// de [grantInvulnerability], que bloqueia DANO. Existe pro Peixe Neutro
  /// (Escamas Escorregadias, ver PIVOT_NEUTRO): a criatura ainda pode levar
  /// dano normal, só não é lentificada/cegada/empurrada enquanto durar.
  void grantStatusImmunity(double seconds);

  void startJump({
    required Vector2 direction,
    required double distance,
    required double duration,
    double height = 16.0,
    VoidCallback? onLand,
  });

  /// Distância real que dá pra avançar em [dir] antes de bater em parede ou
  /// obstáculo sólido — usada pelas habilidades de dash/esquiva (que movem
  /// via `MoveByEffect`, um tween de posição que não passa pelo
  /// `onCollision` a cada frame) pra não atravessar paredes finas de uma vez.
  Vector2 dashOffsetLivre(Vector2 dir, double distancia);

  /// Energia da habilidade 1 — substituiu o cooldown fixo (ver
  /// `Player.dispararAbility1`). Regenera sozinha em `energiaRegenPorSegundo`;
  /// cada execução consome `Ability.custoEnergia` (ajustado por `cdMult`, o
  /// mesmo upgrade que antes só encurtava cooldown).
  double energia = energiaMaxPadrao;
  double energiaMax = energiaMaxPadrao;

  /// Regeneração por segundo. Campo, e não a const [energiaRegenPorSegundo]
  /// direto, porque o upgrade `energyRegenUp` multiplica isto. Como
  /// `trocarCriatura` não recalcula nem isto nem [energiaMax] a partir da
  /// criatura nova (ao contrário de `maxHealth`/`shieldMax`), os dois upgrades
  /// atravessam a troca sem precisar de campo de bônus à parte.
  double energiaRegen = energiaRegenPorSegundo;

  /// Segundos que faltam pra regeneração voltar a correr. Reiniciado a cada
  /// disparo da habilidade 1 (ver `Player.dispararAbility1`).
  double energiaRegenPausa = 0.0;

  // --- Ganchos usados pelas habilidades das criaturas ---
  // Neutros por padrão: nada muda enquanto nenhuma habilidade os usa.
  bool shieldVisualActive = false;
  bool speedLocked = false;
  double damageReduction = 0.0;
  bool refleteProjetil = false;

  /// Ouriço Elétrico — enquanto true, cada golpe absorvido por [shieldHits]
  /// dispara uma explosão elétrica em volta do usuário (ver Escudo de Espinhos).
  bool retaliaEspinhos = false;
  double retaliaDano = 0.0;
  double retaliaStunDuration = 0.0;

  /// Cargas da bolha, da mais antiga pra mais nova.
  ///
  /// Era um `int shieldHits` único que cinco fontes escreviam com `=`, e cada
  /// habilidade zerava no fim do prazo — então lançar a bolha por cima do
  /// item ESCUDO sobrescrevia o item, e o prazo da bolha depois matava os
  /// dois. Guardar a fonte de cada carga resolve isso e mais duas coisas que
  /// um contador único não conseguia: a expiração devolve só o que aquela
  /// fonte pôs, e o dano sabe QUAL carga gastar (ver [consumirEscudo]).
  final List<_CargaEscudo> _cargasEscudo = [];

  /// Quantos golpes a bolha ainda absorve no total. Derivado — ninguém
  /// escreve aqui; use [adicionarEscudoTemporario], [adicionarEscudoPermanente],
  /// [consumirEscudo] e [limparEscudos].
  int get shieldHits =>
      _cargasEscudo.fold(0, (total, carga) => total + carga.golpes);

  /// Escudo COM prazo. Some sozinho depois de [duracao], levando embora só as
  /// cargas que ele mesmo pôs.
  void adicionarEscudoTemporario(Object chave, int golpes, double duracao) {
    aplicarEfeito(
      chave,
      duracao,
      aoIniciar: () {
        _cargasEscudo.add(_CargaEscudo(chave, golpes));
        shieldVisualActive = true;
      },
      aoTerminar: () {
        _cargasEscudo.removeWhere((carga) => carga.chave == chave);
        if (shieldHits <= 0) shieldVisualActive = false;
      },
    );
  }

  /// Escudo SEM prazo (item consumível ESCUDO): só sai quando um golpe o
  /// consome, e só depois de todo escudo temporário ter sido gasto.
  void adicionarEscudoPermanente(int golpes) {
    _cargasEscudo.add(_CargaEscudo(null, golpes));
    shieldVisualActive = true;
  }

  /// Gasta UM golpe da bolha. Devolve false se não havia nenhum — é o que o
  /// chamador usa pra decidir se o dano segue pro escudo passivo/HP.
  ///
  /// Ordem: temporário antes de permanente e, entre temporários, o mais
  /// recente primeiro. O escudo com prazo ia sumir sozinho de qualquer jeito,
  /// então gastá-lo primeiro é o que impede o jogador de perder o escudo que
  /// pagou com um item enquanto uma bolha de habilidade estava ativa.
  bool consumirEscudo() {
    if (_cargasEscudo.isEmpty) return false;

    var alvo = _cargasEscudo.lastIndexWhere((carga) => carga.chave != null);
    if (alvo < 0) alvo = _cargasEscudo.length - 1; // só sobrou permanente

    final carga = _cargasEscudo[alvo];
    carga.golpes--;
    if (carga.golpes <= 0) {
      _cargasEscudo.removeAt(alvo);
      // Cancela o prazo junto: sem carga nenhuma ele não teria mais o que
      // devolver, e deixá-lo correndo só adiaria a limpeza.
      if (carga.chave != null) removerEfeito(carga.chave!);
    }
    if (shieldHits <= 0) shieldVisualActive = false;
    return true;
  }

  /// Zera a bolha inteira, temporária e permanente (troca de criatura).
  void limparEscudos() {
    _cargasEscudo.clear();
    shieldVisualActive = false;
  }
}
