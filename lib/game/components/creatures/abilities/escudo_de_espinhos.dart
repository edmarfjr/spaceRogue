import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';

/// Ouriço Elétrico — botão B. Não evita dano, converte: por [duracao], os
/// próximos [golpes] hits que o usuário levar são absorvidos e cada um
/// dispara uma explosão elétrica com atordoamento ao redor dele. Sem essa
/// habilidade ativa o ouriço não tem defesa nenhuma — apanhar de propósito
/// só compensa dentro da janela.
class EscudoDeEspinhos extends Ability {
  final int golpes;
  final double duracao;
  final double coefDano;
  final double duracaoStun;

  const EscudoDeEspinhos({
    this.golpes = 2,
    this.duracao = 3.5,
    this.coefDano = 0.5,
    this.duracaoStun = 1.0,
  }) : super(
         nome: 'Escudo de Espinhos',
         descricao:
             'Absorve os próximos golpes e revida cada um com uma explosão elétrica atordoante.',
         cooldown: 7.0,
         tipo: AbilityTipo.defesa,
       );

  @override
  void execute(AbilityUser user, Vector2 dir) {
    user.shieldHits = golpes;
    user.shieldVisualActive = true;
    user.retaliaEspinhos = true;
    user.retaliaDano = user.creatureData.stats.ataque * coefDano;
    user.retaliaStunDuration = duracaoStun;

    Future.delayed(Duration(milliseconds: (duracao * 1000).round()), () {
      if (user.isMounted) {
        if (user.shieldHits > 0) {
          user.shieldHits = 0;
          user.shieldVisualActive = false;
        }
        user.retaliaEspinhos = false;
      }
    });
  }
}
