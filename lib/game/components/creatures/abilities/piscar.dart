import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/effects/aura_pulse_effect.dart';
import 'package:creatures_rogue/game/components/effects/ghost_effect.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';

/// Zapeye — botão B. Teleporte curto: some e reaparece no ponto da mira, com
/// i-frames na chegada.
///
/// Único teleporte do elenco — as outras esquivas são dashes que PERCORREM o
/// caminho e param no obstáculo. Este não percorre, então atravessa buraco e
/// pedra. Não atravessa parede: o ponto de chegada tem que estar no chão da
/// sala atual (ver `Player.deslocamentoDoPiscar`), senão o jogador cairia na
/// sala vizinha sem passar pela troca de sala, ou escaparia de sala trancada.
class Piscar extends Ability {
  final double distancia;
  final double invulneravel;

  /// Clarão que atordoa no ponto de PARTIDA (só na evolução). 0 = nenhum.
  final double atordoamentoNaPartida;

  const Piscar({
    this.distancia = 48,
    this.invulneravel = 0.25,
    this.atordoamentoNaPartida = 0,
    super.nome = 'Piscar',
    super.descricao =
        'Teleporte curto até a mira, atravessando buracos e pedras.',
  }) : super(
         cooldown: 4.0,
         target: AbilityTarget.plrDir,
         tipo: AbilityTipo.esquiva,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    if (user is! Player) return;
    final salto = user.deslocamentoDoPiscar(dir, distancia);
    if (salto == null) return;

    final partida = user.position.clone();
    user.parent?.add(
      GhostEffect.fromSprite(user.visual, duration: 0.3, startOpacity: 0.6),
    );
    user.position += salto;
    user.grantInvulnerability(invulneravel);

    final cor1 = user.creatureData.corClara;
    final cor2 = user.creatureData.corEscura;
    for (final ponto in [partida, user.position.clone()]) {
      user.parent?.add(
        AuraPulseEffect(position: ponto, raio: 12, cor1: cor1, cor2: cor2),
      );
    }

    if (atordoamentoNaPartida > 0) {
      user.parent?.add(
        ExplosionHitbox(
          position: partida,
          dmg: user.creatureData.stats.ataque * 0.5,
          stunDuration: atordoamentoNaPartida,
          knockback: 0,
          size: Vector2.all(36),
          tipo: user.creatureData.tipo,
          cor1: Palette.amarelo,
          cor2: Palette.branco,
        ),
      );
    }
  }
}

/// Evolução de [Piscar]: o ponto de onde a criatura sumiu explode num clarão
/// que atordoa quem estiver ali. Fugir de um cerco vira deixar o cerco
/// atordoado pra trás.
class PiscarFulminante extends Piscar {
  const PiscarFulminante()
    : super(
        atordoamentoNaPartida: 1.2,
        nome: 'Piscar Fulminante',
        descricao: 'Teleporte curto que deixa um clarão atordoante onde você estava.',
      );
}
