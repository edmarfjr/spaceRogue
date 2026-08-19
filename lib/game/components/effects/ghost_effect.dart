import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Cópia parada do sprite de quem chama, que desaparece gradualmente
/// (alpha caindo até sumir). Usado pra rastro visual de investidas/dashes:
/// spawne um a cada poucos quadros durante o movimento pra deixar um rastro
/// de "fantasmas" atrás de quem se moveu.
class GhostEffect extends SpriteComponent {
  final double duration;
  final double startOpacity;
  double _elapsed = 0.0;

  GhostEffect({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    Anchor anchor = Anchor.center,
    double angle = 0.0,
    Vector2? scale,
    this.duration = 0.4,
    this.startOpacity = 0.6,
  }) : super(
         sprite: sprite,
         position: position.clone(),
         size: size.clone(),
         anchor: anchor,
         angle: angle,
         paint: Paint()..filterQuality = FilterQuality.none,
       ) {
    if (scale != null) this.scale = scale.clone();
    setOpacity(startOpacity);
  }

  /// Copia aparência (sprite/tamanho/escala/ângulo) e posição atual de
  /// [source] — normalmente `Player.visual` ou `Enemy.visual` — e larga um
  /// fantasma parado bem ali, no mundo.
  factory GhostEffect.fromSprite(
    SpriteComponent source, {
    double duration = 0.4,
    double startOpacity = 0.6,
  }) {
    return GhostEffect(
      sprite: source.sprite!,
      position: source.absolutePosition.clone(),
      size: source.size.clone(),
      anchor: source.anchor,
      angle: source.angle,
      scale: source.scale.clone(),
      duration: duration,
      startOpacity: startOpacity,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final t = (_elapsed / duration).clamp(0.0, 1.0);
    setOpacity(startOpacity * (1 - t));

    if (_elapsed >= duration) removeFromParent();
  }

  /// Agenda [count] fantasmas de [visual], espaçados ao longo de
  /// [overDuration]s — o jeito rápido de dar rastro a um dash/investida
  /// curto sem precisar de um hook por quadro. [add] é quem efetivamente
  /// bota o fantasma no mundo, normalmente `(g) => user.parent?.add(g)`.
  static void spawnTrail({
    required SpriteComponent visual,
    required void Function(GhostEffect ghost) add,
    required double overDuration,
    int count = 3,
    double startOpacity = 0.5,
    double ghostDuration = 0.3,
  }) {
    for (int i = 1; i <= count; i++) {
      final delayMs = (overDuration * i / (count + 1) * 1000).round();
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!visual.isMounted) return;
        add(GhostEffect.fromSprite(visual, duration: ghostDuration, startOpacity: startOpacity));
      });
    }
  }
}
