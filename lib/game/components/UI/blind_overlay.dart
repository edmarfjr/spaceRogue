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
/// desenha nada quando `cegoTimer` está zerado e o jogador não está dentro de
/// `Cogumelos`.
///
/// Duas fontes independentes fecham a mesma vinheta: `cegoTimer` (debuff com
/// duração, causado por inimigo) e `dentroCogumelo` (terreno — dura enquanto
/// os pés estiverem dentro, sem timer, com transição suave própria via
/// [_cogumeloT]). O raio final é o menor dos dois, então o efeito mais forte
/// sempre vence.
class BlindOverlay extends PositionComponent {
  final Player player;

  /// A câmera é fixa por sala, não segue o jogador, então o centro da viewport
  /// não é o centro do jogador. Sem essa referência a vinheta abriria o buraco
  /// no meio da tela e cegaria o jogador justamente onde ele está.
  final CameraComponent camera;

  /// Raio do buraco visível quando a cegueira está no auge, e quando está
  /// prestes a acabar. Interpolar entre os dois é o que dá a sensação de a
  /// visão voltando aos poucos.
  static const double _raioMinimo = 24.0;
  static const double _raioMaximo = 96.0;

  /// Fração da duração gasta abrindo e fechando a vinheta. O miolo do tempo
  /// fica no raio mínimo.
  static const double _fracaoTransicao = 0.25;

  /// Progresso da vinheta do cogumelo: 0 = visão normal, 1 = fechada no
  /// mínimo. Sobe/desce a uma velocidade fixa (fecha/abre em 0.25s), em vez
  /// de reiniciar um timer de debuff a cada frame de colisão — é isso que
  /// segura a vinheta fechada de forma contínua enquanto o jogador está
  /// dentro, sem piscar.
  double _cogumeloT = 0.0;
  static const double _velocidadeCogumelo = 1 / 0.25;

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
  void update(double dt) {
    super.update(dt);
    final alvo = player.dentroCogumelo ? 1.0 : 0.0;
    final passo = _velocidadeCogumelo * dt;
    if (_cogumeloT < alvo) {
      _cogumeloT = (_cogumeloT + passo).clamp(0.0, 1.0);
    } else if (_cogumeloT > alvo) {
      _cogumeloT = (_cogumeloT - passo).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    if (player.cegoTimer <= 0 && _cogumeloT <= 0) return;

    double raioCegueira = _raioMaximo;
    if (player.cegoTimer > 0) {
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
      raioCegueira = _raioMaximo + (_raioMinimo - _raioMaximo) * t;
    }

    final raioCogumelo = _raioMaximo + (_raioMinimo - _raioMaximo) * _cogumeloT;
    final raio = raioCegueira < raioCogumelo ? raioCegueira : raioCogumelo;

    // viewfinder.position é o ponto do mundo que cai no centro da viewport.
    final desloc = player.absolutePosition - camera.viewfinder.position;

    // Durante a transição de sala a câmera leva ~0.4s pra alcançar o
    // jogador (que já teleportou pra sala nova na hora — ver
    // `_checkCameraTransition`), então `desloc` pode ficar bem maior que a
    // tela nesse meio-tempo. Sem o clamp o buraco saía inteiro de vista e a
    // vinheta cobria a tela toda de preto até a câmera assentar.
    final centro = Offset(
      (size.x / 2 + desloc.x).clamp(0.0, size.x),
      (size.y / 2 + desloc.y).clamp(0.0, size.y),
    );

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
