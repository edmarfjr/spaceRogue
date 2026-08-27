import 'package:flame/components.dart';
import '../../core/palette.dart';
import '../../player/player.dart';
import '../../projeteis/projectile.dart';
import '../passive.dart';

/// Caranguejo Ermitão de Fogo — antes era `RecolherNoCasco` (botão B). Ao
/// travar o laço de captura, solta a mesma nuvem de fumaça da habilidade
/// original: não dá dano, cega e atrasa quem estiver por perto — cobertura
/// pra janela de vulnerabilidade da volta (ver PIVOT_TREINADOR.md §4.1).
///
/// Cores fixas (vermelho/cinzaEsc — as mesmas do Caranguejo no registry),
/// não `player.creatureData.corClara/corEscura`: o treinador não carrega
/// cor da criatura dona da passiva, só a da forma que ele escolheu no
/// início da run (ver PIVOT_TREINADOR.md §3.7) — as duas quase nunca
/// coincidem. Mesmo motivo de `TornadoResidual`/`PecoenhaReflexiva`
/// hardcodarem a cor em vez de tentar herdar.
class FumacaAoLacar extends Passive {
  final double duracaoCegueira;
  final double duracaoLentidao;
  const FumacaAoLacar({this.duracaoCegueira = 2.5, this.duracaoLentidao = 3.0})
      : super(nome: 'Fumaça ao Laçar', descricao: 'Iniciar o laço de captura solta uma fumaça que cega e atrasa quem estiver perto.');

  @override
  void aoIniciarLaco(Player player) {
    player.parent?.add(Projectile(
      position: player.position.clone(),
      direction: Vector2.zero(),
      speed: 0,
      dmg: 0,
      kbForce: 0,
      sprPath: 'projeteis/nuvem.png',
      cor1: Palette.vermelho,
      cor2: Palette.cinzaEsc,
      cegoDuracao: duracaoCegueira,
      lentidaoDuracao: duracaoLentidao,
      atravessa: 10,
      size: Vector2(24, 24),
      lifeTime: 2.5,
      radius: 12,
    ));
  }
}
