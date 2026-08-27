import 'dart:math';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/ability_user.dart';
import 'package:creatures_rogue/game/components/projeteis/orbit_projectile.dart';

/// Toco de Madeira — botão A. Sem mira: [quantidade] espinhos passam a girar
/// ao redor do usuário por [duracao], acertando quem encostar. É contato
/// constante, não tiro — a defesa dele é literalmente ficar perto de ninguém.
/// Dano = ataque da criatura × [coef] — ver BaseStats.
class FolhasNavalha extends Ability {
  final double coef;
  final int quantidade;
  final double raio;
  final double velocidadeAngular;
  final double duracao;

  const FolhasNavalha({
    this.coef = 0.35,
    this.quantidade = 5,
    this.raio = 20,
    this.velocidadeAngular = 4.0,
    this.duracao = 4.0,
  }) : super(nome: 'Folhas Navalha', descricao: 'Espinhos giram ao redor do usuário, acertando quem encostar.', cooldown: 6.5);

  @override
  void execute(AbilityUser user, Vector2 dir) {
    final dano = user.creatureData.stats.ataque * coef;
    for (int i = 0; i < quantidade; i++) {
      final anguloInicial = (2 * pi / quantidade) * i;
      user.parent?.add(OrbitProjectile(
        owner: user,
        anguloAtual: anguloInicial,
        raio: raio,
        velocidadeAngular: velocidadeAngular,
        dmg: dano,
        lifeTime: duracao,
        sprPath: 'projeteis/folha.png',
        cor1: Palette.verde,
        cor2: Palette.verdeEsc,
        tipo: user.creatureData.tipo,
        
      ));
    }
  }
}
