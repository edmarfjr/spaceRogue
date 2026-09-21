import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/passive.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/effects/efeitos_temporarios.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Roda de Fogo — criatura SEM habilidade 1; esta passiva ocupa o lugar dela.
///
/// Na velocidade máxima a criatura vira um projétil: ignora dano de CONTATO de
/// inimigos e machuca quem encostar nela. Perde as duas coisas assim que
/// desacelera, então o jogo dela é manter a linha reta.
///
/// Só escreve em dois campos do `Player` ([Player.imuneAContato] e
/// [Player.danoDeContato]) e não toca em colisão nenhuma: quem resolve o
/// contato é o `Player.onCollision`, que já era o único lugar que sabia disso.
/// Assim a passiva não duplica regra de colisão e o `Player` não precisa saber
/// que a Roda de Fogo existe.
///
/// Atribuição a cada quadro, não par de ligar/desligar: é idempotente, então
/// não há estado pra desfazer se a criatura for trocada no meio (o
/// `trocarCriatura` zera os dois campos, e a criatura nova os reescreve —
/// ou não, se não tiver passiva).
class RodaDeFogo extends Passive {
  const RodaDeFogo({this.limiarVelocidade = 0.75, this.coefDano = 1.5})
    : super(nome: 'Roda de Fogo');

  /// Fração de [Player.maxSpeed] a partir da qual conta como velocidade
  /// máxima. Não é 1.0 porque `velocity` é clampado em `maxSpeed` e comparar
  /// ponto flutuante por igualdade quase nunca bate.
  ///
  /// Relativo, e não absoluto, de propósito: `maxSpeed` já desconta lentidão,
  /// grama alta e o upgrade de velocidade, então o limiar continua alcançável
  /// em qualquer um desses estados.
  final double limiarVelocidade;

  /// Dano de contato = `ataque * coefDano`, com a trava de reacerto do
  /// `Player` (0,3s por inimigo).
  final double coefDano;

  @override
  void aoAtualizar(Player player, double dt) {
    final maxima = player.maxSpeed;
    final naMaxima =
        maxima > 0 && player.velocity.length >= maxima * limiarVelocidade;

    player.imuneAContato = naMaxima;
    player.danoDeContato = naMaxima
        ? player.creatureData.stats.ataque * coefDano
        : 0.0;
  }
}

/// Evolução de [RodaDeFogo]: mantém a imunidade e o dano de contato na
/// velocidade máxima, e passa a deixar um RASTRO DE FOGO no chão.
///
/// O rastro sai em duas situações, porque uma não cobre a outra:
/// - na velocidade máxima, o mesmo gatilho da forma base;
/// - durante a esquiva, que é um `MoveByEffect` e por isso NÃO mexe em
///   `velocity` — sem este segundo caso, o dash da criatura de fogo sairia
///   sem fogo nenhum.
///
/// A cadência do rastro vem de um efeito temporário com `EfeitoStack.ignora`:
/// enquanto a condição valer, reaplicar não faz nada, e quando ele expira o
/// `aoTerminar` larga uma chama e o quadro seguinte rearma. Isso dá um tique
/// periódico sem a passiva precisar guardar cronômetro — ela é `const`.
class RodaDeFogoEvo extends RodaDeFogo {
  const RodaDeFogoEvo({
    super.limiarVelocidade,
    super.coefDano,
    this.intervaloRastro = 0.08,
    this.coefRastro = 0.6,
    this.duracaoChama = 2.0,
    this.janelaDash = 0.35,
  });

  /// Segundos entre uma chama e a próxima.
  final double intervaloRastro;

  /// Dano de cada chama = `ataque * coefRastro`.
  final double coefRastro;

  /// Quanto cada chama fica no chão.
  final double duracaoChama;

  /// Por quanto tempo depois da esquiva o rastro continua saindo. Fixo, e
  /// maior que a duração de qualquer dash do jogo (~0,15–0,2s), porque
  /// `Ability` não expõe duração — cada subclasse guarda a sua.
  final double janelaDash;

  @override
  void aoEsquivar(Player player, Vector2 direcao) {
    // Só marca a janela; quem larga as chamas é o [aoAtualizar], então o
    // rastro do dash e o da velocidade usam exatamente o mesmo caminho.
    player.aplicarEfeito(#rodaFogoDash, janelaDash);
  }

  @override
  void aoAtualizar(Player player, double dt) {
    super.aoAtualizar(player, dt);

    final naMaxima = player.danoDeContato > 0;
    if (!naMaxima && !player.temEfeito(#rodaFogoDash)) return;

    player.aplicarEfeito(
      #rodaFogoRastro,
      intervaloRastro,
      stack: EfeitoStack.ignora,
      aoTerminar: () => _largarChama(player),
    );
  }

  void _largarChama(Player player) {
    player.parent?.add(
      Projectile(
        owner: player,
        position: player.position.clone(),
        direction: Vector2.zero(),
        speed: 0,
        lifeTime: duracaoChama,
        dmg: player.creatureData.stats.ataque * coefRastro,
        sprPath: 'projeteis/fogo2.png',
        cor1: Palette.laranja,
        cor2: Palette.vermelho,
        tipo: player.creatureData.tipo,
        radius: 5,
        // Alto porque a chama fica parada no chão e vai ser atravessada por
        // vários inimigos ao longo dos 2s — o `hitCooldown` do `Projectile`
        // já impede reacerto rápido no mesmo alvo.
        atravessa: 100,
        dotKind: DotKind.queimadura,
        dotTicks: 3,
        // Sem som: com uma chama a cada 0,08s, tocar o sfx de fogo em cada
        // uma estouraria o throttle do `GameAudio` e abafaria todo o resto.
        playSfx: false,
      ),
    );
  }
}
