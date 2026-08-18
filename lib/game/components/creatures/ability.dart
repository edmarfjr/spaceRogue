import 'package:flame/components.dart';
import '../player/player.dart';
enum AbilityTarget { plrDir, enemyDir, joyDir }
abstract class Ability {
  final String nome;
  final double cooldown;
  final AbilityTarget target;

  const Ability({required this.nome, required this.cooldown, this.target = AbilityTarget.enemyDir});

  /// Chamada quando o botão é pressionado e o cooldown já zerou.
  /// [dir] é a direção de mira, derivada do movimento do usuário.
  void execute(Player user, Vector2 dir);
}
