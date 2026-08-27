import 'package:flame/components.dart';
import 'ability_user.dart';
enum AbilityTarget { plrDir, enemyDir, joyDir }
enum AbilityTipo {ataque,defesa,esquiva}
abstract class Ability {
  final String nome;
  final double cooldown;
  final AbilityTarget target;
  final AbilityTipo tipo;

  const Ability({required this.nome, required this.cooldown, this.target = AbilityTarget.enemyDir, this.tipo = AbilityTipo.ataque});

  /// Se false, o botão não dispara e o cooldown não é consumido — usado por
  /// habilidades que dependem de um recurso externo ao cooldown (ex.: bomba
  /// do treinador, ver PIVOT_TREINADOR.md §3.2). Default: sempre executável.
  bool canExecute(AbilityUser user) => true;

  /// Chamada quando o botão é pressionado e o cooldown já zerou.
  /// [dir] é a direção de mira, derivada do movimento do usuário.
  void execute(AbilityUser user, Vector2 dir);
}
