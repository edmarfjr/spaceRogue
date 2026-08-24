import 'package:flame/components.dart';
import '../player/player.dart';
enum AbilityTarget { plrDir, enemyDir, joyDir }
enum AbilityTipo {ataque,defesa,esquiva}
abstract class Ability {
  final String nome;
  final double cooldown;
  final AbilityTarget target;
  final AbilityTipo tipo;

  const Ability({required this.nome, required this.cooldown, this.target = AbilityTarget.enemyDir, this.tipo = AbilityTipo.ataque});

  /// Chamada quando o botão é pressionado e o cooldown já zerou.
  /// [dir] é a direção de mira, derivada do movimento do usuário.
  void execute(Player user, Vector2 dir);
}
