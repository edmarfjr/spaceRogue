# Pivô de design: de roguelike estilo Isaac para roguelike de criaturas estilo Pokémon Quest

Documento de implementação. Descreve a mudança de direção do SpaceRogue e a ordem
em que ela deve ser aplicada no código atual.

## 1. O que muda

O jogo deixa de ter um protagonista fixo com mira analógica e passa a girar em torno
de **criaturas**. Cada criatura existe em duas formas: como personagem jogável (escolhido
antes da run) e como inimigo (com comportamento próprio de IA). As quatro mudanças
principais são:

1. **Sprites estáticos.** Sai a animação quadro a quadro; entra um sprite único por
   criatura, animado por transformação (escala, posição, rotação) em tempo de execução.
   É o visual do Pokémon clássico: o desenho não muda, o desenho se mexe.
2. **Dois botões de ação.** O joystick de mira desaparece. Cada criatura tem duas
   habilidades, uma por botão, normalmente uma ofensiva e uma defensiva.
3. **Seletor de criatura.** Antes de cada run o jogador escolhe entre as criaturas
   desbloqueadas.
4. **Criaturas com identidade.** Cada uma tem status base próprios, um tipo elemental
   e as duas habilidades.

## 2. Decisões já travadas

- **Sem MP.** O único portão de uso de habilidade é o cooldown. Pokémon Quest funciona
  assim, e ter MP junto com cooldown seria dois recursos medindo a mesma coisa.
  `BaseStats` não tem campo de mana.
- **Barra de HP, não corações.** O `Hud` atual deriva meio-corações de
  `maxHealth / 2`, o que quebra visualmente quando cada criatura tem um HP máximo
  diferente (8 contra 20). A HUD passa a ser uma barra de vida mais dois indicadores
  de cooldown, um por botão.
- **Todos os sprites são grayscale.** O pipeline continua passando por
  `PaletteSwapper.createSwappedImage`, com os valores de cinza que o projeto já usa
  (169 para cinza claro, 84 para cinza escuro, 255 para branco). Isso significa que
  uma única arte de criatura pode gerar variantes elementais sem custo de asset — vale
  usar isso para variantes de inimigo mais adiante.

## 3. Arquitetura

O princípio: **`Player` e `Enemy` compartilham dado, não hierarquia.**

Não criar uma classe base comum entre os dois. `Enemy` exige `playerTarget` no construtor
e todo o seu `update` pressupõe IA; `Player` carrega joystick, invulnerabilidade temporária
e a flag `naoMove` usada na transição de sala. Uma base comum viraria um depósito de
condicionais. O que os dois compartilham é o **dado da criatura**.

### 3.1 Novos arquivos

```
lib/game/components/creatures/creature_type.dart
lib/game/components/creatures/base_stats.dart
lib/game/components/creatures/ability.dart
lib/game/components/creatures/creature_data.dart
lib/game/components/creatures/creature_registry.dart
lib/game/components/creatures/abilities/   (uma classe por habilidade)
```

### 3.2 `CreatureType` e a tabela de tipos

```dart
enum CreatureType { fogo, planta, agua, eletrico, neutro }

/// Multiplicador de dano de [atacante] contra [defensor].
double typeMultiplier(CreatureType atacante, CreatureType defensor) { ... }
```

Tabela (vantagem 1.5x, desvantagem 0.75x, resto 1.0x):

| Atacante | 1.5x contra | 0.75x contra |
|----------|-------------|--------------|
| fogo     | planta      | agua         |
| planta   | agua        | fogo         |
| agua     | fogo        | eletrico     |
| eletrico | agua        | planta       |

O tipo entra em `Projectile` como campo novo. `Enemy.takeDamage` e `Player.takeDamage`
aplicam o multiplicador antes de subtrair a vida.

### 3.3 `BaseStats`

```dart
class BaseStats {
  final int maxHp;
  final double speed;    // vira maxSpeed no Player e speed no Enemy
  final double defesa;   // dano final = dano * (1 - defesa * 0.08), mínimo 1
  final double ataque;   // multiplicador de dano das habilidades
  const BaseStats({...});
}
```

A fórmula de defesa é intencionalmente simples e o resultado é clampado em no mínimo
1 de dano. Não vale construir um sistema de atributos genérico agora.

### 3.4 `Ability`

Toda habilidade precisa reduzir a um dos quatro primitivos que já existem no projeto.
Se não reduzir, é caro demais para este protótipo:

- spawn de `Projectile` (já parametrizado: sprite, cor1/cor2, dano, velocidade, knockback)
- hitbox de área — `ExplosionHitbox` já faz isso, incluindo o crescimento por escala
- flag de buff temporizada no próprio ator (não um sistema de efeitos genérico)
- dash / deslocamento de posição

```dart
abstract class Ability {
  final String nome;
  final double cooldown;
  const Ability({required this.nome, required this.cooldown});

  /// Chamada quando o botão é pressionado e o cooldown já zerou.
  /// [dir] é a direção de mira derivada do movimento (ver fase 3).
  void execute(Player user, Vector2 dir);
}
```

As implementações concretas são classes curtas e **sem estado próprio** — o cooldown
é contado pelo `Player`, não pela habilidade. Isso permite que a mesma instância seja
compartilhada entre o jogador e a versão inimiga da criatura.

### 3.5 `CreatureData` e o registry

```dart
typedef EnemyBuilder = Enemy Function(Vector2 position, Player playerTarget);

class CreatureData {
  final String id;
  final String nome;
  final String spritePath;
  final Vector2 srcPosition;   // recorte na spritesheet, se houver
  final CreatureType tipo;
  final Color corClara;
  final Color corEscura;
  final BaseStats stats;
  final Ability ability1;
  final Ability ability2;
  final EnemyBuilder enemyBuilder;  // como esta criatura se comporta como inimigo
  const CreatureData({...});
}

class CreatureRegistry {
  static const List<CreatureData> all = [
    roedorFogo, tartarugaPlanta, sapoAgua, aveEletrica,
  ];
  static CreatureData byId(String id) => ...;
}
```

O `EnemySpawner` mantém a lista de pesos, mas passa a construir a partir do
`enemyBuilder` de cada `CreatureData` em vez de importar cada classe de inimigo
diretamente.

## 4. As criaturas

Valores iniciais, para tunar depois de jogar.

### 4.1 Roedor de Fogo — tipo fogo

Ágil e com bastante poder de fogo, porém frágil.

| Stat   | Valor |
|--------|-------|
| maxHp  | 8     |
| speed  | 70    |
| defesa | 1     |
| ataque | 3     |

- **Botão A — Rajada de Brasa.** Três projéteis num leque de aproximadamente 20 graus.
  Cooldown 0.8s, dano 2 por projétil. Teto de dano alto em curta distância, desperdício
  em distância longa.
  Primitivo: três `Projectile` com direções rotacionadas.
- **Botão B — Disparada Flamejante.** Dash rápido na direção do movimento atual, com
  invulnerabilidade durante o deslocamento, deixando duas hitboxes de rastro no caminho.
  Cooldown 4s. Para uma criatura frágil, mobilidade **é** a defesa.
  Primitivo: dash (interpolação de posição por tempo fixo) mais `ExplosionHitbox` de
  raio pequeno e dano baixo.

### 4.2 Tartaruga de Planta — tipo planta

Resistente, porém lenta.

| Stat   | Valor |
|--------|-------|
| maxHp  | 20    |
| speed  | 35    |
| defesa | 4     |
| ataque | 3     |

- **Botão A — Cuspe de Semente.** Projétil lento, dano 4, `kbForce` alto. Cooldown 1.4s.
  Empurra o inimigo para longe, o que compensa a lentidão de reposicionamento.
  Primitivo: `Projectile` com `speed` baixa e `kbForce` alta.
- **Botão B — Casco Fechado.** Buff de 2.5s: dano recebido reduzido em 85% e **velocidade
  travada em zero**. Cooldown 6s. É o Withdraw do Pokémon Quest — trocar mobilidade por
  sobrevivência é a decisão que define a criatura.
  Primitivo: flag temporizada no `Player`, lida em `takeDamage` e no movimento.

### 4.3 Sapo de Água — tipo agua

Balanceado e confiável.

| Stat   | Valor |
|--------|-------|
| maxHp  | 14    |
| speed  | 50    |
| defesa | 2     |
| ataque | 2     |

- **Botão A — Jato d'Água.** Projétil reto e rápido, dano 3, cooldown 0.6s. Sem truque:
  é a linha de base contra a qual as outras habilidades ofensivas são comparadas.
  Primitivo: `Projectile`.
- **Botão B — Bolha Protetora.** Escudo que absorve um golpe, com duração de 5s.
  Cooldown 7s. Ao estourar (por dano ou por tempo), empurra inimigos próximos.
  Primitivo: flag temporizada mais `ExplosionHitbox` com dano 0 e knockback.

### 4.4 Ave de Eletricidade — tipo eletrico

Veloz e resistente, com ataques leves e rápidos.

| Stat   | Valor |
|--------|-------|
| maxHp  | 12    |
| speed  | 80    |
| defesa | 3     |
| ataque | 1     |

- **Botão A — Bico Elétrico.** Cooldown 0.25s, dano 1, projétil muito rápido e de
  alcance curto (`speed` alta somada a um tempo de vida curto no projétil). O DPS vem
  do volume, não do golpe.
  Primitivo: `Projectile` — exige adicionar um `lifeTime` opcional em `Projectile`.
- **Botão B — Corrente Estática.** Área circular em volta do jogador: dano 1 mais
  atordoamento que zera a `speed` dos inimigos atingidos por 1.5s. Cooldown 5s.
  É a habilidade de quebrar cerco, o defensivo de quem luta colado.
  Primitivo: `ExplosionHitbox` mais um campo `stunTimer` em `Enemy`, checado no `update`
  antes de chamar `movimento(dt)`.

## 5. Fases de implementação

A ordem importa: as fases 2 e 3 deixam o novo esquema de controle jogável antes do
refactor mais arriscado (fase 4).

### Fase 1 — Dado puro

Criar `CreatureType`, `BaseStats`, `Ability`, `CreatureData`, `CreatureRegistry` e as
oito classes de habilidade. Nada é consumido ainda; nenhum arquivo existente muda.
Ao fim desta fase o jogo continua rodando exatamente como antes.

### Fase 2 — Player com sprite estático

Arquivo: `lib/game/components/player/player.dart`.

Isto é majoritariamente **deleção**. Saem:

- `bodyVerticalAnim`, `bodyHorizontalAnim` e os dois `SpriteAnimation.fromFrameData`
- `headSprites`, `weaponSprites`, `head`, `weapon`, `currentAimIndex`
- todo o `_updateAiming`, incluindo o `switch` de prioridade da arma
- o `enum AimDirection`

Entram:

- um único `SpriteComponent visual`, carregado de `creatureData.spritePath` via
  `PaletteSwapper` com `corClara`/`corEscura` da criatura
- direção de frente derivada do movimento: espelhar `visual` horizontalmente quando
  `velocity.x` troca de sinal, exatamente como os mixins de inimigo já fazem
- os stats passam a vir de `creatureData.stats` em vez de constantes no campo
  (`maxSpeed`, `maxHealth`, `dmg`)

O construtor de `Player` passa a receber `CreatureData` e apenas o `moveJoystick`.

**Animação idle:** usar `ScaleEffect` de respiração no `visual` (por exemplo, escala
1.0 para 1.06 em Y, com `EffectController(infinite: true, alternate: true)`).
Ver a armadilha na seção 7 antes de usar `MoveEffect`.

### Fase 3 — Dois botões de ação

Arquivos: `lib/game/space_rogue_game.dart` e `player.dart`.

- Remover `aimJoystick` de `_setupJoysticks` e do construtor de `Player`.
- Remover o bloco de setas em `Player.onKeyEvent` que preenchia `_keyboardAim`;
  mapear as habilidades para duas teclas (por exemplo `Z` e `X`).
- Adicionar dois `HudButtonComponent` no jogo, fora do `World`, com o mesmo
  tratamento de HUD que os joysticks já recebem hoje.
- Em `Player`: dois timers de cooldown (`_cd1`, `_cd2`), decrementados no `update`;
  ao apertar o botão, se o timer estiver zerado, chamar
  `creatureData.ability1.execute(this, aimDirection)` e recarregar o timer.
- **Direção de mira:** deriva do movimento. Guardar a última direção não-nula de
  `velocity` normalizada; se o jogador estiver parado, usar a última direção conhecida.
  O campo `lockedFireDirection`, que já existe e já é usado pela bomba, serve para isso —
  basta passar a alimentá-lo pelo movimento em vez de pelo joystick de mira.

Ao fim desta fase o esquema de controle novo é jogável com a criatura padrão. **Jogar
e tunar cooldowns antes de seguir.**

### Fase 4 — Inimigos com sprite estático

Arquivos: `enemy.dart`, `enemy_mixins.dart`, os oito arquivos em `enemies/dung1/` e
`dummy_enemy.dart`.

Esta é a fase cara, e o custo não está nos sprites: **está nos mixins, que derivam
tempo a partir de contagem de frames.** Os pontos exatos:

- `ShooterAttack.setupAttackAnimation()` calcula `attackDuration = (frames - 1) * frameTime`,
  e `updateAttack` usa esse valor como duração do estado de ataque.
- `JumpMovement.setupJumpAnimations({idle, prep, air, prepTime})` e `InvestidaMovement`,
  idem; `SlimeEnemy` calcula `prepTime: (prepFrames - 1) * prepStepTime`.
- Os dois mixins trocam `visual.animation` e chamam `visual.animationTicker?.reset()`
  como sinal visual da máquina de estados.
- `ShooterAttack` e `SlimeEnemy` recuperam a imagem já palette-swapped através de
  `visual.animation!.frames.first.sprite.image`.

A conversão:

1. `Enemy.visual` passa de `SpriteAnimationComponent` para `SpriteComponent`.
2. O parâmetro `animationData` sai do construtor de `Enemy`.
3. Cada duração vira um **número explícito** no arquivo do inimigo
   (`attackDuration = 0.3`, `prepDuration = 0.3`), não mais derivada de frames.
4. O sinal visual de cada estado vira uma transformação: agachar na preparação é
   `ScaleEffect` para (1.2, 0.8); esticar no ar é (0.85, 1.15); recuo de tiro é
   um `MoveEffect` curto contra a direção do disparo.
5. `visual.animation!.frames.first.sprite.image` vira `visual.sprite!.image`.

Converter **um** inimigo primeiro — `SlimeEnemy`, que usa `JumpMovement`, o mixin mais
acoplado a animação —, validar em jogo, e só então propagar para os outros.

### Fase 5 — Seleção de criatura antes da run

Arquivos: `space_rogue_game.dart`, `main.dart`, novo overlay.

Hoje `SpacerogueGame.onLoad` constrói o `player` incondicionalmente, e tanto
`resetGame()` quanto `nextLevel()` assumem que ele já existe e nunca é recriado.

A mudança de menor risco é **não** reinicializar o player no lugar, e sim mover a
construção para um método novo:

```dart
void startRun(CreatureData creature) {
  player = Player(moveJoystick: moveJoystick, creatureData: creature);
  player.onDeath = onGameOver;
  player.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);
  dungeonWorld.add(player);
  // geração da dungeon e posicionamento da câmera, hoje inline no onLoad
}
```

`onLoad` deixa de criar o player e apenas prepara mundo, câmera, joystick e HUD;
o jogo continua abrindo pausado no menu, como já faz. O `MainMenuOverlay` passa a
levar a uma tela nova (`CreatureSelectOverlay`) que lista `CreatureRegistry.all`,
mostra nome, tipo, stats e as duas habilidades, e chama `game.startRun(escolhida)`.

Atenção: `RoomComponent` recebe `player:` no construtor, então a geração da dungeon
precisa acontecer **depois** da criação do player, dentro de `startRun`.

Desbloqueio de criaturas: por enquanto, todas desbloqueadas. Deixar um
`Set<String> unlockedIds` no jogo para plugar persistência depois, sem inventar
sistema de save agora.

### Fase 6 — Tipos e HUD nova

- Adicionar `CreatureType tipo` a `Projectile` e a `ExplosionHitbox`.
- Aplicar `typeMultiplier` em `Enemy.takeDamage` e `Player.takeDamage`.
- `Player.onCollision` hoje aplica `takeDamage(1)` fixo ao encostar em qualquer
  `Enemy`; passar a usar o stat de ataque do inimigo.
- Reescrever `Hud.render`: barra de HP (retângulo de fundo mais retângulo proporcional
  a `currentHealth / maxHealth`) e dois indicadores de cooldown, um por botão,
  preenchendo conforme `1 - cd / cooldownTotal`. Os sprites de coração deixam de ser
  carregados.

## 6. Assets

Sprites de criatura em grayscale, 16x16, um arquivo por criatura:

```
assets/images/actors/creatures/roedor_fogo.png
assets/images/actors/creatures/tartaruga_planta.png
assets/images/actors/creatures/sapo_agua.png
assets/images/actors/creatures/ave_eletrica.png
```

Valores de cinza obrigatórios, porque `PaletteSwapper` compara pixel a pixel:
169 para cinza claro, 84 para cinza escuro, 255 para branco, 0 para preto.
Qualquer outro tom passa intacto e aparece cinza dentro do jogo.

Como o sprite é estático e a câmera é de cima, um único quadro virado para a frente
basta; o espelhamento horizontal cobre esquerda e direita.

## 7. Armadilhas

**Animar `visual`, nunca o `PositionComponent` pai.** As hitboxes e a sombra são
irmãos do `visual`, posicionados a partir de `size`. Escalar o componente pai
desalinha colisão e sombra. O código já usa essa separação: `JumpMovement` escreve
`visual.position.y` e compensa `enemyHitbox.position.y` separadamente.

**Bob de idle com `MoveEffect` briga com `JumpMovement`.** O mixin atribui
`visual.position.y` diretamente todo frame, o que sobrescreve o efeito (ou é
sobrescrito por ele, dependendo da ordem de update). Usar `ScaleEffect` para a
respiração de idle, e validar em um inimigo antes de generalizar.

**Duplicação entre `player.dart` e `enemy.dart`.** `isPhysicsCollision`, o
`CircleComponent` de sombra, a montagem do `physicsHitbox` e o bloco de resolução
de parede são quase idênticos nos dois arquivos. É duplicação real, mas extrair isso
não faz parte deste pivô — deixar como está.

**`PaletteSwapper` tem cache por caminho mais cores.** Cada combinação nova gera uma
textura nova em tempo de execução. Adicionar as combinações das criaturas ao
`_preloadCombatSprites` do jogo para não gerar textura em pleno combate.

## 8. Checklist

- [ ] Fase 1: `CreatureType`, `BaseStats`, `Ability`, `CreatureData`, `CreatureRegistry`, 8 habilidades
- [ ] Sprites grayscale das 4 criaturas em `assets/images/actors/creatures/`
- [ ] Fase 2: `Player` com sprite estático, stats vindos de `CreatureData`, facing por movimento
- [ ] Fase 3: dois botões, cooldowns, remoção do `aimJoystick`, mira derivada do movimento
- [ ] Jogar e tunar cooldowns antes de seguir
- [ ] Fase 4: `SlimeEnemy` convertido e validado, depois os outros oito arquivos
- [ ] Fase 5: `startRun(CreatureData)` e `CreatureSelectOverlay`
- [ ] Fase 6: tabela de tipos aplicada, HUD com barra de HP e indicadores de cooldown
