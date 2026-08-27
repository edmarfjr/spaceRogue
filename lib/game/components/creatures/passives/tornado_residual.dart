import 'package:flame/components.dart';
import '../../core/palette.dart';
import '../../player/player.dart';
import '../../projeteis/projectile.dart';
import '../passive.dart';

/// Tornado de Fogo — antes era `EsquivaTornado` (botão B). Toda esquiva
/// deixa um tornado parado no ponto de partida (projétil de velocidade 0,
/// perfura 10 alvos, dura 3s) — mesma peça da habilidade original, só que
/// sem rastro de dano no dash em si, porque quem machuca agora é o tornado
/// deixado pra trás.
class TornadoResidual extends Passive {
  final double coef;
  const TornadoResidual({this.coef = 0.5}) : super(nome: 'Tornado Residual', descricao: 'Toda esquiva do treinador deixa um tornado parado no ponto de partida, perfurando quem passar por ele.');

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    player.parent?.add(Projectile(
      position: player.position.clone(),
      direction: Vector2.zero(),
      speed: 0,
      lifeTime: 3,
      dmg: player.creatureData.stats.ataque * coef,
      sprPath: 'projeteis/tornado.png',
      cor1: Palette.vermelho,
      cor2: Palette.laranja,
      radius: 8,
      atravessa: 10,
    ));
  }
}
