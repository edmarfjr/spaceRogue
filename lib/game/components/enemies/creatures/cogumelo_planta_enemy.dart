import 'package:flame/components.dart';

import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
import 'package:creatures_rogue/game/components/projeteis/projectile.dart';
import '../enemy.dart';

/// Cogumelo de Planta como inimigo: NÃO persegue. Fica onde nasceu soltando
/// nuvens de esporo, e estoura numa nuvem grande ao morrer.
///
/// É a forma inimiga mais diferente do elenco de propósito. Quase todo inimigo
/// do jogo corre atrás do jogador; um que ocupa território muda a leitura da
/// sala — ele não é uma ameaça que chega até você, é um pedaço de chão que
/// você precisa contornar ou pagar pra limpar.
///
/// A morte venenosa é o que fecha o raciocínio: matar de perto custa caro, mas
/// o bicho é parado, então matar de longe é sempre possível. A punição existe
/// pra quem tem pressa.
///
/// Não herda a mecânica de condução da forma jogável (o esporo que segue o
/// movimento de quem atirou) por um motivo simples: um inimigo parado não tem
/// movimento pra conduzir nada.
class CogumeloPlantaEnemy extends Enemy {
  /// Segundos entre uma nuvem e a próxima.
  static const double _intervaloNuvem = 2.2;

  /// Só solta nuvem com o jogador por perto. Sem isto, uma sala com três
  /// cogumelos ficaria coberta de veneno antes de o jogador chegar nela.
  static const double _alcanceAtivacao = 80.0;

  static const double _duracaoNuvem = 3.5;
  static const double _raioNuvem = 12.0;
  static const double _coefNuvem = 0.6;

  static const double _raioMorte = 22.0;
  static const double _coefMorte = 1.0;

  double _timer = 0.0;

  CogumeloPlantaEnemy({required super.position, required super.playerTarget})
    : super(
        creature: CreatureRegistry.cogumeloPlanta,
        // Velocidade zero: o `movimento` abaixo nem chama o vaguear. O campo
        // existe porque `Enemy` o exige, e deixá-lo em zero deixa explícito
        // que este inimigo não anda.
        speed: 0,
        health: 10,
        dmg: 1,
        // Não é empurrado: um cogumelo que desliza pela sala ao levar tiro
        // perderia justamente o que ele é, um obstáculo fixo.
        isPushable: false,
      );

  @override
  void movimento(double dt) {
    final distancia = (playerTarget.absolutePosition - absolutePosition).length;
    if (distancia > _alcanceAtivacao) return;

    _timer += dt;
    if (_timer < _intervaloNuvem) return;
    _timer = 0.0;
    _soltarNuvem(_raioNuvem, _coefNuvem, _duracaoNuvem);
  }

  @override
  void death() {
    // Antes do `super`, que remove este componente da árvore — depois dele
    // não haveria `parent` pra receber a nuvem.
    _soltarNuvem(_raioMorte, _coefMorte, _duracaoNuvem);
    super.death();
  }

  void _soltarNuvem(double raio, double coef, double duracao) {
    parent?.add(
      Projectile(
        owner: this,
        position: position.clone(),
        direction: Vector2.zero(),
        speed: 0,
        isEnemy: true,
        dmg: dmg * coef,
        kbForce: 0,
        sprPath: 'projeteis/nuvem.png',
        cor1: creature?.corClara ?? CreatureRegistry.cogumeloPlanta.corClara,
        cor2: creature?.corEscura ?? CreatureRegistry.cogumeloPlanta.corEscura,
        tipo: creature?.tipo ?? CreatureRegistry.cogumeloPlanta.tipo,
        dotKind: DotKind.veneno,
        dotTicks: 2,
        atravessa: 100,
        size: Vector2.all(raio * 2),
        lifeTime: duracao,
        radius: raio,
      ),
    );
  }
}
