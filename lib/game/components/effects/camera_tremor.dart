import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

/// Sacode a câmera por alguns instantes — o lado visual do feedback de dano
/// (ver `Player.takeDamage`).
///
/// Escreve direto em `viewfinder.position` em vez de usar um efeito do Flame
/// porque a câmera deste jogo NÃO segue o jogador: ela fica parada no centro
/// da sala e só se mexe na troca de sala, por um `MoveToEffect`. Ou seja, o
/// canal está livre quase o tempo todo, e um efeito sobreposto a outro efeito
/// no mesmo canal é justamente o que daria briga.
///
/// SEMPRE pelo setter (`viewfinder.position = ...`), nunca mutando em cima do
/// que o getter devolve. `Viewfinder.position` não guarda um vetor: o getter
/// é `-transform.offset`, que ALOCA um Vector2 novo a cada leitura. Um
/// `position.setFrom(...)` compila, roda e não faz nada — mexe num objeto
/// descartável —, e foi exatamente assim que a primeira versão deste
/// componente saiu: sem tremida nenhuma, em qualquer amplitude.
///
/// Quem vai mexer na câmera pelos outros dois caminhos (o corte seco de troca
/// de andar e o `MoveToEffect` da troca de sala) precisa chamar [parar]
/// antes — ver a doc daquele método.
class CameraTremor extends Component {
  CameraTremor(this.viewfinder);

  final Viewfinder viewfinder;

  /// Onde a câmera estava antes do tremor começar. `null` = não há tremor em
  /// curso, e este componente não encosta em nada.
  Vector2? _base;

  double _restante = 0.0;
  double _duracao = 0.0;
  double _amplitude = 0.0;

  final Random _rng = Random();

  /// Amplitude padrão, em pixels de JOGO — a câmera é
  /// `withFixedResolution(160, 144)`, então 2px aqui viram vários na tela.
  static const double amplitudePadrao = 5.0;

  static const double duracaoPadrao = 0.3;

  void disparar({
    double amplitude = amplitudePadrao,
    double duracao = duracaoPadrao,
  }) {
    // A base é capturada só na PRIMEIRA sacudida: um segundo golpe durante a
    // primeira pegaria a posição já deslocada, e a câmera terminaria o tremor
    // fora do lugar — de um punhado de pixels por golpe encadeado.
    _base ??= viewfinder.position.clone();

    // Fica com o golpe mais forte em vez de somar. Dois acertos no mesmo
    // quadro (o corpo do inimigo mais um projétil dele) são rotina, e somar
    // mandaria a tela voando num caso que o jogador lê como um golpe só.
    if (amplitude > _amplitude) _amplitude = amplitude;
    if (duracao > _restante) _restante = duracao;
    _duracao = _restante;
  }

  /// Devolve a câmera ao lugar AGORA, e desliga.
  ///
  /// Precisa ser chamado por quem for escrever `viewfinder.position` na mão
  /// ou pendurar um efeito nela: os dois disputariam este mesmo canal, e o
  /// tremor venceria todo quadro — no fim ele restauraria a base ANTIGA e a
  /// câmera ficaria travada na sala de onde o jogador saiu.
  ///
  /// Chamar antes de mexer na câmera, não depois: aqui a posição volta pra
  /// base, e é isso que o chamador sobrescreve em seguida.
  void parar() {
    final base = _base;
    if (base != null) viewfinder.position = base;
    _base = null;
    _restante = 0.0;
    _amplitude = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final base = _base;
    if (base == null) return;

    _restante -= dt;
    if (_restante <= 0) {
      parar();
      return;
    }

    // Perde força ao longo do tremor: uma sacudida que para de uma vez lê
    // como engasgo de quadro, não como impacto.
    final forca = _amplitude * (_restante / _duracao);

    // Arredondado pra pixel inteiro de propósito. Num deslocamento quebrado a
    // câmera de resolução fixa reamostra a cena inteira, e a arte toda
    // cintila em vez de sacudir — o pior dos dois mundos numa tela de 160x144.
    viewfinder.position =
        base +
        Vector2(
          ((_rng.nextDouble() * 2 - 1) * forca).roundToDouble(),
          ((_rng.nextDouble() * 2 - 1) * forca).roundToDouble(),
        );
  }
}
