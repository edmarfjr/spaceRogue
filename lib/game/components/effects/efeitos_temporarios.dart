import 'package:flame/components.dart';

/// Quem é dono de um efeito temporário — é isso que decide o que a troca de
/// criatura leva embora.
enum EfeitoDono {
  /// Estado de combate da criatura ativa (bolha de escudo, redução de dano de
  /// uma habilidade). Morre na troca: `PIVOT_CONTROLE_DIRETO.md §2.3` manda a
  /// criatura que sai levar só a vida salva, o resto é descartado.
  criatura,

  /// Bônus do jogador (item, upgrade de run). ATRAVESSA a troca, pelo mesmo
  /// motivo que `bonusHpItens` atravessa: quem pegou foi o jogador, não a
  /// criatura. Sem esta separação, um efeito que COMEÇA na troca seria
  /// apagado pela própria limpeza da troca.
  jogador,
}

/// O que fazer quando um efeito é reaplicado antes de acabar.
enum EfeitoStack {
  /// Reinicia a duração do zero (padrão — é o que quase todo buff quer).
  renova,

  /// Soma à duração que sobrava.
  soma,

  /// Mantém o que já estava valendo e descarta a reaplicação.
  ignora,
}

class _Efeito {
  _Efeito(this.dono, this.restante, this.aoTerminar);
  final EfeitoDono dono;
  double restante;
  final void Function()? aoTerminar;
}

/// Efeitos com duração, tocados pelo `update` de quem usa o mixin.
///
/// Substitui o padrão `Future.delayed` espalhado pelas habilidades. Três
/// motivos concretos, não estéticos:
///
/// 1. `Future.delayed` ignora pausa. O jogo pausado não roda `update`, mas o
///    `Future` continua contando — a bolha de escudo expirava com o jogo
///    parado no menu.
/// 2. `Future.delayed` não dá pra cancelar. O efeito voltava a mexer no
///    jogador mesmo depois da criatura sair, morrer, ou a run acabar.
/// 3. Ninguém conseguia ler o tempo restante, então a Hud não tinha como
///    mostrar um indicador.
///
/// CONTRATO: todo caminho de remoção (fim natural, [removerEfeito],
/// [limparEfeitos]) executa `aoTerminar` EXATAMENTE uma vez. Efeitos que
/// mexem em estado compartilhado — o caso típico é somar em `Player.danoMult`
/// no início e subtrair no fim — dependem disso. Pular a chamada em algum
/// caminho deixa o bônus grudado pelo resto da run, que é exatamente o tipo
/// de acúmulo silencioso que já mordeu este projeto nos power-ups.
mixin EfeitosTemporarios on Component {
  final Map<Object, _Efeito> _efeitos = {};

  bool temEfeito(Object chave) => _efeitos.containsKey(chave);

  /// Segundos que faltam, ou 0 se o efeito não está ativo. Pensado pra Hud.
  double restanteDe(Object chave) => _efeitos[chave]?.restante ?? 0.0;

  /// [chave] identifica o efeito pra reaplicação e cancelamento — use um
  /// símbolo (`#revezamento`) ou um enum, nunca uma string montada na hora.
  ///
  /// `aoIniciar` só roda quando o efeito realmente começa: reaplicar um efeito
  /// que já está de pé mexe na duração e mais nada, senão um buff que soma em
  /// `danoMult` somaria de novo a cada reaplicação sem nunca subtrair.
  void aplicarEfeito(
    Object chave,
    double duracao, {
    EfeitoDono dono = EfeitoDono.criatura,
    EfeitoStack stack = EfeitoStack.renova,
    void Function()? aoIniciar,
    void Function()? aoTerminar,
  }) {
    final atual = _efeitos[chave];
    if (atual != null) {
      switch (stack) {
        case EfeitoStack.ignora:
          break;
        case EfeitoStack.renova:
          atual.restante = duracao;
        case EfeitoStack.soma:
          atual.restante += duracao;
      }
      return;
    }
    _efeitos[chave] = _Efeito(dono, duracao, aoTerminar);
    aoIniciar?.call();
  }

  void removerEfeito(Object chave) =>
      _efeitos.remove(chave)?.aoTerminar?.call();

  /// Remove os efeitos de [dono], ou todos se [dono] for nulo. Sempre executa
  /// o `aoTerminar` de cada um — ver CONTRATO na doc do mixin.
  void limparEfeitos({EfeitoDono? dono}) {
    final chaves = dono == null
        ? _efeitos.keys.toList()
        : _efeitos.entries
              .where((e) => e.value.dono == dono)
              .map((e) => e.key)
              .toList();
    for (final chave in chaves) {
      removerEfeito(chave);
    }
  }

  /// Chame no `update`. Só decrementa aqui: a lista de expirados é montada
  /// antes de remover porque `aoTerminar` pode aplicar outro efeito.
  void atualizarEfeitos(double dt) {
    if (_efeitos.isEmpty) return;
    List<Object>? expirados;
    for (final entry in _efeitos.entries) {
      entry.value.restante -= dt;
      if (entry.value.restante <= 0) {
        (expirados ??= <Object>[]).add(entry.key);
      }
    }
    if (expirados == null) return;
    for (final chave in expirados) {
      removerEfeito(chave);
    }
  }
}
