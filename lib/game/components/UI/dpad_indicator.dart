import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, Paint, FilterQuality, Canvas;
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Indicador visual de um dos dois joysticks (esquerdo/movimento ou
/// direito/ataque — ver [spritePath]): tira de 240x48, 5 quadros de 48x48 —
/// repouso, direita, baixo, esquerda, cima, nessa ordem (`ui/dpad.png` pro
/// movimento, `ui/apad.png` pro ataque).
///
/// Flutuante feito posição, ao contrário do manípulo antigo: nasce onde o
/// dedo ENTRA na tela (ver [posicao] — lê `DynamicJoystickComponent.
/// ultimoToqueAbsoluto`) e, diferente do manípulo, não some quando o dedo
/// sai — fica parado nesse último lugar, só o quadro volta a repouso. Nada
/// desenhado até o primeiro toque da run.
///
/// Puramente visual — a captura de toque/cálculo de direção continua sendo
/// o `DynamicJoystickComponent`, este componente só lê [posicao] e
/// [direcao] dele pra se posicionar e escolher o quadro.
class DPadIndicator extends PositionComponent with HasGameReference {
  /// Abaixo disso o toque ainda não "decidiu" um eixo — mostra repouso, pra
  /// não ficar piscando de quadro com tremor de dedo perto do centro.
  static const double _zonaMorta = 0.35;

  final Vector2? Function() posicao;
  final Vector2 Function() direcao;
  final String spritePath;

  /// Cores que substituem o cinza claro/escuro do desenho original (ver
  /// `UiTheme.dpadCor1`/`dpadCor2` e `apadCor1`/`apadCor2`) — mesmo
  /// `PaletteSwapper` usado pelos sprites de criatura.
  final Color cor1;
  final Color cor2;

  late final List<Sprite> _quadros;

  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  DPadIndicator({
    required this.posicao,
    required this.direcao,
    required this.spritePath,
    required this.cor1,
    required this.cor2,
    required double tamanho,
  }) : super(size: Vector2.all(tamanho), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final ui.Image imagem = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
    );
    _quadros = List.generate(
      5,
      (i) => Sprite(
        imagem,
        srcPosition: Vector2(i * imagem.height.toDouble(), 0),
        srcSize: Vector2(imagem.height.toDouble(), imagem.height.toDouble()),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final p = posicao();
    if (p != null) position = p;
  }

  /// 0 repouso, 1 direita, 2 baixo, 3 esquerda, 4 cima — mesma trava nos 4
  /// eixos cardeais que a mira da habilidade 1 usa (ver
  /// `Player._direcaoAtaqueTravada`): o maior componente (x ou y) decide o
  /// eixo, nunca diagonal.
  int get _quadroAtual {
    final d = direcao();
    if (d.length2 < _zonaMorta * _zonaMorta) return 0;
    if (d.x.abs() >= d.y.abs()) {
      return d.x > 0 ? 1 : 3;
    }
    return d.y > 0 ? 2 : 4;
  }

  @override
  void render(Canvas canvas) {
    if (posicao() == null) return;
    _quadros[_quadroAtual].render(canvas, size: size, overridePaint: _paint);
  }
}
