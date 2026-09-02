import 'package:flame/components.dart';
import '../player/player.dart';

/// Habilidade passiva de uma criatura, separada de `ability1`/`ability2`
/// (ver PIVOT_TREINADOR.md). Diferente de `Ability`, uma `Passive` nunca é
/// "executada" pelo jogador: ela vale **enquanto a criatura estiver no grupo
/// do jogador**, ativa ou no banco — decisão travada com o usuário, não é
/// "só a ativa" nem "só as fora do banco".
///
/// Consequência direta dessa regra: uma `Passive` nunca pode depender de
/// posição, alvo ou HP da própria criatura — no banco ela não existe no
/// mundo. Toda `Passive` é centrada no `Player`, pendurada em `Player.dodge`
/// ou `Player.takeDamage`.
///
/// `const`/stateless por design, igual `Ability`: o conjunto de passivas
/// ativas é lido a cada uso direto de `Player.game` (ver
/// `Player.passivasAtivas`), nunca cacheado — elimina qualquer ponto de
/// recálculo que precisaria ser lembrado em captura/dispensa/início de run.
/// Estado que uma passiva precisa acumular ao longo do tempo (ex.: tempo sem
/// apanhar, ver Sapo de Água) mora no `Player`, nunca na instância de
/// `Passive` — várias criaturas no registry compartilham a MESMA instância
/// `const`, então um campo mutável aqui vazaria entre runs.
abstract class Passive {
  final String nome;

  /// Texto curto, voltado pro jogador, pro card de seleção de criatura
  /// (`creature_select_overlay.dart`) e pros cards de equipe no menu de
  /// pausa — diferente dos comentários `///` de cada classe, que documentam
  /// de qual `Ability` original a passiva veio.
  final String descricao;

  /// Multiplicadores aplicados à esquiva do treinador (`Player.dodge`) —
  /// 1.0 = sem efeito. Lidos no momento da esquiva, nunca cacheados, então
  /// múltiplas criaturas com o mesmo multiplicador compõem por produto (não
  /// tunado — primeiro corte, mesmo padrão do resto do pivô).
  final double dodgeCooldownMult;
  final double dodgeDistanceMult;

  const Passive({
    required this.nome,
    required this.descricao,
    this.dodgeCooldownMult = 1.0,
    this.dodgeDistanceMult = 1.0,
  });

  /// Chamado dentro de `Player.dodge()`, depois do dash já decidido e
  /// disparado — só serve pra efeitos ADITIVOS (rastro, explosão na saída ou
  /// na chegada). Não pode vetar nem substituir o dash em si; pra mudar a
  /// direção, ver [direcaoEsquivaOverride].
  void aoEsquivar(Player player, Vector2 direcao) {}

  /// Chamado uma vez por dash, antes do `MoveByEffect` ser montado — dá a
  /// uma criatura a chance de trocar a direção padrão (afastar do
  /// movimento/velocity) por outra. Retornar `null` mantém a direção padrão.
  /// Só uma passiva do grupo deve sobrescrever isso na prática; se mais de
  /// uma tentar, a última processada ganha — sem prioridade definida.
  Vector2? direcaoEsquivaOverride(Player player, Vector2 direcaoPadrao) => null;

  /// Chamado no início de `Player.takeDamage`, depois do i-frame já setado e
  /// depois do dano já mitigado por `damageReduction`, mas ANTES de
  /// `shieldHits`/escudo passivo consumirem o golpe — dispara mesmo que o
  /// golpe acabe inteiramente absorvido pelo escudo logo em seguida. Se o
  /// grupo tiver mais de uma criatura com retaliação, todas executam, uma
  /// depois da outra.
  void aoTentarTomarDano(Player player, double amount) {}

  /// Chamado todo frame a partir de `Player.update`. Neutro por padrão —
  /// só sobrescrever quando o efeito precisar observar o tempo passando
  /// (ex.: recarregar um escudo depois de N segundos sem apanhar).
  void aoAtualizar(Player player, double dt) {}
}
