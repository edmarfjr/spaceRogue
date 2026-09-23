import 'dart:math' show max;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:creatures_rogue/game/components/UI/consumable_slot_button.dart';
import 'package:creatures_rogue/game/game_settings.dart';

/// Joystick "flutuante": ao contrário do `JoystickComponent` fixo do Flame,
/// não tem posição própria na tela. Ele cobre uma área (metade esquerda ou
/// direita da tela, ver [ladoDireito]) só pra capturar o toque; no instante
/// em que o dedo encosta, o visual (fundo + manípulo) nasce ali mesmo, e
/// some quando o dedo sai.
///
/// [knob]/[background] são opcionais: o joystick de movimento não usa mais
/// manípulo flutuante (ver `DPadIndicator`, um indicador fixo que lê
/// [relativeDelta] daqui) — só a captura de toque e a matemática de direção
/// deste componente. Quando nulos, a área ainda captura o arrasto
/// normalmente, só não desenha nada.
///
/// A matemática de `delta`/`intensity`/`relativeDelta` é a mesma do
/// `JoystickComponent` original do Flame — só o "centro" deixou de ser fixo
/// no `onMount` (campo privado da lib do Flame, inacessível por herança) pra
/// ser recalculado a cada toque em `onDragStart`.
class DynamicJoystickComponent extends PositionComponent
    with DragCallbacks, TapCallbacks {
  final PositionComponent? knob;
  final PositionComponent? background;
  final double knobRadius;

  /// `false` = área de captura na metade ESQUERDA da tela (movimento);
  /// `true` = metade DIREITA (mira/ataque). Cada instância cobre só a
  /// metade que lhe cabe, senão um toque do lado errado ativaria as duas.
  final bool ladoDireito;

  /// Chamado quando um toque nesta metade da tela terminou SEM virar arrasto.
  /// `null` = ninguém escutando, que é o caso no esquema de BOTÕES.
  ///
  /// Quem separa toque de arrasto é a arena de gestos do Flutter, não conta
  /// de tempo nem de distância feita aqui. `DragCallbacks` roda sobre
  /// `ImmediateMultiDragGestureRecognizer`, que só aceita o gesto quando o
  /// dedo passa do `kTouchSlop` (~18px, ver `_ImmediatePointerState.
  /// checkForResolutionAfterMove` no SDK) — um toque parado NUNCA gera
  /// `onDragStart`. Então:
  ///
  /// - dedo entra e sai sem andar: só o reconhecedor de toque se interessa,
  ///   e [onTapUp] dispara;
  /// - dedo anda mais de 18px: o arrasto vence a arena, o toque é cancelado
  ///   (`onTapCancel`) e o joystick mira como sempre.
  ///
  /// Sem limite de duração de propósito: segurar o dedo parado não faz mais
  /// nada neste jogo, então soltar depois de um tempão ainda é um toque.
  void Function()? onToqueRapido;

  /// Dois toques rápidos seguidos nesta metade da tela.
  ///
  /// Dois toques rápidos seguidos nesta metade da tela.
  ///
  /// [onToqueRapido] dispara nos DOIS toques, sem esperar pra ver se vem o
  /// segundo. Já tentamos o contrário — segurar o simples em suspenso até a
  /// janela do duplo fechar — e a latência de 200ms em TODO disparo se sentia
  /// como travamento, então foi revertido. O custo aceito é o oposto: um
  /// toque duplo também dispara a ação de toque simples.
  void Function()? onToqueDuplo;

  /// Janela entre um toque e o seguinte pra contarem como duplo. 300ms é o
  /// mesmo tempo que o Flutter usa no `DoubleTapGestureRecognizer`.
  static const int _intervaloToqueDuplo = 300;

  int _ultimoToqueMs = 0;

  final Vector2 delta = Vector2.zero();
  final Vector2 _unscaledDelta = Vector2.zero();
  Vector2 _baseKnobPosition = Vector2.zero();
  bool _active = false;

  double intensity = 0.0;

  /// Onde o dedo ENTROU na tela pela última vez, em coordenadas do jogo
  /// (absoluta, não local a este componente) — `null` até o primeiro toque.
  /// Só muda no início de um novo toque (`onDragStart`); arrastar não
  /// atualiza, e soltar o dedo não limpa — é o que o `DPadIndicator` lê pra
  /// nascer onde o dedo tocou e continuar ali depois que solta.
  Vector2? ultimoToqueAbsoluto;

  /// Percentual (0..1 por eixo) e direção que o manípulo está puxado a
  /// partir do centro onde o dedo pousou. Zero quando não há toque ativo.
  Vector2 get relativeDelta => _active ? delta / knobRadius : Vector2.zero();

  /// Fração da ALTURA da área de captura onde o centro fixo fica.
  ///
  /// Em RETRATO a área já é a banda do rodapé, então o meio dela é o lugar
  /// certo. Em PAISAGEM a área é meia tela inteira, e o meio dela cairia na
  /// altura dos olhos — o polegar descansa bem mais embaixo.
  static const double _fracaoCentroRetrato = 0.65;
  static const double _fracaoCentroPaisagem = 0.72;

  /// Centro fixo escolhido de fora, em coordenadas LOCAIS. `null` = usa a
  /// regra própria deste componente (ver [_centroFixo]).
  ///
  /// Existe porque em PAISAGEM o centro certo depende de onde a área de jogo
  /// está desenhada, e só o jogo sabe disso — o meio da metade da tela cai
  /// EMBAIXO do vidro da câmera, que é centralizado e ocupa a altura toda.
  /// Quem preenche é `CreaturesRogueGame._reflowControles`, no mesmo lugar
  /// onde os botões de ação já são posicionados por orientação.
  Vector2? centroFixoExterno;

  /// Centro do joystick quando [GameSettings.joysticksFixos] está ligado, em
  /// coordenadas LOCAIS. Derivado de [size] a cada leitura, e não guardado:
  /// `onGameResize` muda a área de captura ao girar o aparelho, e um valor
  /// guardado ficaria no lugar antigo.
  Vector2 get _centroFixo {
    final externo = centroFixoExterno;
    if (externo != null) return externo;

    final fracao = size.y > size.x
        ? _fracaoCentroRetrato
        : _fracaoCentroPaisagem;
    return Vector2(size.x / 2, size.y * fracao);
  }

  /// Onde o indicador (ver `DPadIndicator`) deve se desenhar.
  ///
  /// No modo fixo devolve o centro desde o começo, sem esperar toque nenhum —
  /// um joystick fixo invisível até o jogador adivinhar onde ele está não
  /// seria fixo, seria escondido.
  Vector2? get centroIndicador => GameSettings.instance.joysticksFixos
      ? position + _centroFixo
      : ultimoToqueAbsoluto;

  DynamicJoystickComponent({
    this.knob,
    this.background,
    required Vector2 spawnAreaSize,
    required this.knobRadius,
    this.ladoDireito = false,
  }) : super(size: spawnAreaSize, position: Vector2.zero()) {
    knob?.anchor = Anchor.center;
    background?.anchor = Anchor.center;
  }

  /// Altura mínima da banda de controle inferior no modo RETRATO — grande o
  /// bastante pra caber o manípulo (fundo de até 120px de diâmetro no
  /// celular) com folga. Fixa: não escala com a tela pra não virar uma banda
  /// gigante em celulares muito altos e estreitos (ver [alturaBanda]).
  static const double alturaBandaMinima = 170.0;

  /// Altura da banda de controle inferior no modo RETRATO. Cresce pra deixar
  /// a área de jogo (câmera, ver `CreaturesRogueGame._reposicionarVidro`)
  /// quadrada e ocupando a largura toda, mas nunca fica menor que
  /// [alturaBandaMinima] — senão uma janela só ligeiramente mais alta que
  /// larga (redimensionar a janela do PC devagar passa por aí) deixaria a
  /// banda espremida demais pro manípulo caber.
  static double alturaBanda(Vector2 canvasSize) =>
      max(alturaBandaMinima, canvasSize.y - canvasSize.x);

  static bool retrato(Vector2 canvasSize) => canvasSize.y > canvasSize.x;

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    // A área de captura acompanha o tamanho real da tela — sem isso, girar o
    // aparelho ou redimensionar a janela deixaria a metade torta.
    if (retrato(canvasSize)) {
      // RETRATO: metade esquerda/direita de uma banda presa no rodapé (a
      // área de jogo fica presa no topo, ver `CreaturesRogueGame`) — Game
      // Boy de verdade, controles lado a lado embaixo.
      final altura = alturaBanda(canvasSize);
      size = Vector2(canvasSize.x / 2, altura);
      position = Vector2(
        ladoDireito ? canvasSize.x / 2 : 0,
        canvasSize.y - altura,
      );
    } else {
      // PAISAGEM: metade esquerda/direita da tela inteira, exceto a faixa do
      // topo — é onde vivem os slots do inventário, e um toque neles não
      // pode virar movimento/ataque (ver ConsumableSlotButton).
      size = Vector2(
        canvasSize.x / 2,
        canvasSize.y - ConsumableSlotButton.alturaFaixa,
      );
      position = Vector2(
        ladoDireito ? canvasSize.x / 2 : 0,
        ConsumableSlotButton.alturaFaixa,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    final knobRadius2 = knobRadius * knobRadius;
    delta.setFrom(_unscaledDelta);
    if (delta.length2 > knobRadius2) {
      delta.scaleTo(knobRadius);
    }
    if (knob != null) {
      knob!.position
        ..setFrom(_baseKnobPosition)
        ..add(delta);
    }
    intensity = delta.length2 / knobRadius2;
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _active = true;
    _unscaledDelta.setZero();
    delta.setZero();

    if (GameSettings.instance.joysticksFixos) {
      // Centro preso: o dedo não define mais onde o joystick está, e sim o
      // quanto ele está puxado. Encostar longe do centro já entrega inclinação
      // cheia, que é o comportamento esperado de um direcional fixo.
      //
      // Semear `_unscaledDelta` com essa distância é o que faz o resto do
      // componente continuar valendo sem mudança: `onDragUpdate` soma
      // incrementos, e somar a partir do valor certo mantém a conta igual a
      // "dedo menos centro" o tempo todo.
      _baseKnobPosition = _centroFixo;
      _unscaledDelta.setFrom(event.localPosition - _baseKnobPosition);
    } else {
      _baseKnobPosition = event.localPosition.clone();
    }
    ultimoToqueAbsoluto = position + _baseKnobPosition;
    background?.position = _baseKnobPosition.clone();
    knob?.position = _baseKnobPosition.clone();

    if (background != null && background!.parent == null) add(background!);
    if (knob != null && knob!.parent == null) add(knob!);
    return false;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_active) return false;
    _unscaledDelta.add(event.localDelta);
    return false;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _hide();
    return false;
  }

  /// Chegar aqui já é a prova de que não houve arrasto — ver [onToqueRapido].
  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onToqueRapido?.call();

    final agora = DateTime.now().millisecondsSinceEpoch;
    if (agora - _ultimoToqueMs <= _intervaloToqueDuplo) {
      // Zera pra que um terceiro toque comece um par novo, em vez de formar
      // um segundo duplo com o mesmo toque do meio.
      _ultimoToqueMs = 0;
      onToqueDuplo?.call();
    } else {
      _ultimoToqueMs = agora;
    }
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _hide();
    return false;
  }

  void _hide() {
    _active = false;
    _unscaledDelta.setZero();
    delta.setZero();
    intensity = 0.0;
    background?.removeFromParent();
    knob?.removeFromParent();
  }
}
