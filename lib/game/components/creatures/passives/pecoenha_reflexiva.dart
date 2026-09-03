import 'package:flame/components.dart';
import '../../core/palette.dart';
import '../../effects/dot.dart';
import '../../player/player.dart';
import '../../projeteis/projectile.dart';
import '../passive.dart';

/// Slime de Planta — antes era `ExplosãoVenenosa` (botão B). Adaptação, não
/// port direto: a habilidade original envenenava só quem a explosão
/// acertasse, escolhido pelo jogador. `Player.takeDamage` não carrega
/// referência de quem bateu (`amount` é só o número), então não dá pra mirar
/// "quem te acertou" direto — em vez disso, todo golpe recebido solta uma
/// nuvem venenosa em volta do treinador, que pega o agressor se ele ainda
/// estiver perto (quase sempre o caso, contato ou explosão de curto
/// alcance). Mesmos números da habilidade original.
class PecoenhaReflexiva extends Passive {
  const PecoenhaReflexiva() : super(nome: 'Peçonha Reflexiva', descricao: 'Todo golpe que o treinador tenta tomar solta uma nuvem venenosa ao redor dele.');

  @override
  void aoTentarTomarDano(Player player, double amount) {
    player.parent?.add(Projectile(
        owner: player,
      position: player.position.clone(),
      direction: Vector2.zero(),
      speed: 0,
      dmg: 0,
      kbForce: 0,
      sprPath: 'projeteis/bolaGrande.png',
      cor1: Palette.verde,
      cor2: Palette.verdeEsc,
      dotKind: DotKind.veneno,
      dotTicks: 1,
      atravessa: 10,
      size: Vector2(24, 24),
      lifeTime: 1.5,
      radius: 12,
    ));
  }
}
