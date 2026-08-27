import 'package:flame/components.dart';
import '../../player/player.dart';
import '../passive.dart';

/// Tartaruga de Planta — antes era `CascoFechado` (botão B). Reduzida da
/// versão original: em vez de reduzir dano e travar o movimento, aproveita a
/// janela de i-frames que a esquiva já concede pra também refletir
/// projéteis durante ela — `refleteProjetil` (de `AbilityUser`) já é lido de
/// verdade por `Projectile.onCollisionStart`, só ninguém escrevia nele desde
/// que o treinador parou de executar habilidade de criatura.
class CascoReflexivo extends Passive {
  const CascoReflexivo() : super(nome: 'Casco Reflexivo', descricao: 'Durante os instantes de invulnerabilidade da esquiva, o treinador reflete projéteis.');

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    player.refleteProjetil = true;
    final duracao = player.dodgeIframeDuration;
    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (player.isMounted) player.refleteProjetil = false;
    });
  }
}
