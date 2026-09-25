import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';

/// Cogumelo de Planta — botão B. Escudo de um golpe que, ao ESTOURAR, deixa
/// uma nuvem de esporos no lugar.
///
/// Fecha o kit da criatura: o botão A planta nuvem onde você quiser, levando
/// ela pelo campo; o botão B planta nuvem onde você apanhou. Nenhuma outra
/// criatura do elenco converte dano recebido em terreno.
///
/// Estoura, não murcha: o `aoEstourar` da carga de escudo só roda quando o
/// último golpe dela é absorvido (ver `AbilityUser.adicionarEscudoTemporario`).
/// Se o prazo vencer sem ninguém encostar, nada é solto — o casulo que acaba
/// sozinho seca, não arrebenta.
class CasuloDeEsporos extends Ability {
  final double duracao;

  /// Quanto tempo a nuvem fica no chão depois do estouro.
  final double duracaoNuvem;

  final double coefNuvem;
  final int ticksVeneno;
  final double raioNuvem;

  const CasuloDeEsporos({
    this.duracao = 5.0,
    this.duracaoNuvem = 4.0,
    this.coefNuvem = 0.5,
    this.ticksVeneno = 3,
    this.raioNuvem = 14,
  }) : super(
         nome: 'Casulo de Esporos',
         descricao:
             'Escudo que absorve um golpe e estoura numa nuvem de esporos.',
         cooldown: 6.0,
         tipo: AbilityTipo.defesa,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.adicionarEscudoTemporario(
      #casuloDeEsporos,
      1,
      duracao,
      aoEstourar: () => soltarNuvem(
        user,
        coefNuvem: coefNuvem,
        ticksVeneno: ticksVeneno,
        raio: raioNuvem,
        duracao: duracaoNuvem,
      ),
    );
  }

  /// Compartilhado com a forma evoluída, que muda só os números.
  ///
  /// `speed: 0` e `atravessa` alto: é o mesmo jeito que todas as áreas de chão
  /// do jogo são feitas (poça de gelo, rastro de fogo), então a nuvem herda o
  /// comportamento já testado de ficar parada e acertar quem passar.
  static void soltarNuvem(
    AbilityUser user, {
    required double coefNuvem,
    required int ticksVeneno,
    required double raio,
    required double duracao,
  }) {
    user.parent?.add(
      Projectile(
        owner: user,
        position: user.position.clone(),
        direction: Vector2.zero(),
        speed: 0,
        dmg: user.creatureData.stats.ataque * coefNuvem,
        kbForce: 0,
        sprPath: 'projeteis/nuvem.png',
        cor1: user.creatureData.corClara,
        cor2: user.creatureData.corEscura,
        tipo: user.creatureData.tipo,
        dotKind: DotKind.veneno,
        dotTicks: ticksVeneno,
        atravessa: 100,
        size: Vector2.all(raio * 2),
        lifeTime: duracao,
        radius: raio,
      ),
    );
  }
}
