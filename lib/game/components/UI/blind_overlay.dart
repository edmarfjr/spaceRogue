import 'dart:ui';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import '../player/player.dart';

/// Vinheta que fecha em volta do jogador enquanto ele está cego.
///
/// Não é tela preta: os inimigos continuam atirando durante a cegueira, e
/// escurecer tudo transformaria o efeito em sorteio em vez de dificuldade. A
/// vinheta tira a leitura da sala mas mantém visível o perigo colado no
/// jogador — dá pra reagir ao que encosta, não dá pra planejar.
///
/// Vive na viewport da câmera (igual ao HUD) e lê o estado do jogador; não
/// desenha nada quando `cegoTimer` está zerado.
class BlindOverlay extends PositionComponent {
  final Player player;

  /// A câmera é fixa por sala, não segue o jogador, então o centro da viewport
  /// não é o centro do jogador. Sem essa referência a vinheta abriria o buraco
  /// no meio da tela e cegaria o jogador justamente onde ele está.
  final CameraComponent camera;

  /// Raio do buraco visível quando a cegueira está no auge, e quando está
  /// prestes a acabar. Interpolar entre os dois é o que dá a sensação de a
  /// visão voltando aos poucos.
  static const double _raioMinimo = 26.0;
  static const double _raioMaximo = 96.0;

  /// Fração da duração gasta abrindo e fechando a vinheta. O miolo do tempo
  /// fica no raio mínimo.
  static const double _fracaoTransicao = 0.25;

  BlindOverlay({required this.player, required this.camera})
      : super(
          size: Vector2(RoomComponent.roomWidth, RoomComponent.roomHeight),
          // Prioridade maior desenha por cima. O HUD e o minimapa ficam no
          // padrão (0) e a barra de boss em 100, então a vinheta precisa ser
          // negativa: ela escurece o mundo, mas cegar o jogador não pode
          // esconder os corações e o cooldown dele.
          priority: -10,
        );

  @override
  void render(Canvas canvas) {
    if (player.cegoTimer <= 0) return;

    final total = player.cegoDuracaoInicial;
    final decorrido = total - player.cegoTimer;
    final transicao = total * _fracaoTransicao;

    double t; // 0 = visão normal, 1 = cegueira cheia
    if (transicao <= 0) {
      t = 1.0;
    } else if (decorrido < transicao) {
      t = decorrido / transicao;
    } else if (player.cegoTimer < transicao) {
      t = player.cegoTimer / transicao;
    } else {
      t = 1.0;
    }
    t = t.clamp(0.0, 1.0);

    final raio = _raioMaximo + (_raioMinimo - _raioMaximo) * t;

    // viewfinder.position é o ponto do mundo que cai no centro da viewport.
    final desloc = player.absolutePosition - camera.viewfinder.position;
    final centro = Offset(size.x / 2 + desloc.x, size.y / 2 + desloc.y);

    // Buraco redondo recortado de um retângulo preto: tudo que estiver fora do
    // raio some. `difference` é o recorte; sem ele a vinheta cobriria também o
    // que deveria continuar visível.
    final escuro = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.x, size.y)),
      Path()..addOval(Rect.fromCircle(center: centro, radius: raio)),
    );

    canvas.drawPath(escuro, Paint()..color = Palette.preto);
  }
}
