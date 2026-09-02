# Pivô de design: do treinador com grupo autônomo para controle direto com troca de equipe

Documento de implementação. Continua de onde `PIVOT_TREINADOR.md` parou e descreve a
terceira mudança de direção: o jogador deixa de ser o treinador que comanda um grupo
autônomo e volta a **ser** a criatura em campo — como era antes do `PIVOT_TREINADOR.md`
— mas agora com um **grupo de até três criaturas** entre as quais ele troca a ativa em
pleno jogo. A forma de conseguir a segunda e terceira criatura (a captura por laço saiu)
fica para depois — ver seção 5.

Playtest do modelo treinador+companion autônomo (registrado no checklist do
`PIVOT_TREINADOR.md`) mostrou que criatura agindo sozinha, mesmo com override e esquiva
pessoal, deixa a ação fina demais para o roguelike pretendido. Decisão do usuário:
reverter o controle para direto, preservando tudo que foi construído desde o pivô
anterior e que não depende dele.

## 1. O que muda

1. **O jogador volta a ser a criatura ativa.** Sem ator "treinador" separado. `Player`
   deriva sprite, stats e as duas habilidades de `creatureData` de novo, como antes do
   `PIVOT_TREINADOR.md`. Isso inclui o visual: `Player.onLoad` hoje carrega um sprite
   fixo de treinador (`'actors/plr.png'`, `player.dart:539-543`) — volta a carregar
   `creatureData.spritePath` com as cores da criatura, do jeito que `Companion.onLoad`
   já faz hoje. Vale desde a Fase 1 (seção 6), mesmo antes do grupo existir: com uma
   criatura só, o jogador já precisa ver a criatura escolhida, não um treinador genérico.
2. **As criaturas não agem mais sozinhas.** `Companion` (IA de mira, movimento e
   natureza) é removido. Os dois botões de habilidade (A e B) voltam a ser input direto
   do jogador, sem conceito de "override".
3. **Grupo de até três, com troca em pleno jogo.** O jogador tem uma criatura ativa (a
   que ele controla) e até duas em banco. Tocar o retrato de uma criatura do banco na
   HUD troca qual está ativa. A que sai vai para o banco; a que entra assume posição,
   input e câmera.
4. **Sem captura por laço.** A manobra inteira (`Player.startCapture`/`CaptureButton`/
   `CaptureLassoVisual`/`CaptureSwapOverlay`) sai do jogo. No lugar, um mecanismo bem mais
   simples: uma criatura selvagem aparece na sala da escada do quarto andar de cada
   dungeon, e encostar nela recruta — ver seção 5.
5. **O banco vira o "desmaiar" de uma criatura.** Quando a ativa perde toda a vida em
   combate, ela vai para o banco e o jogo troca IMEDIATAMENTE para a próxima do grupo com
   vida `> 0`. Sem cura passiva nenhuma (emenda do usuário — ver 2.3): uma criatura
   derrotada só volta a campo se nunca tiver chegado a 0, ou nunca mais. Sem ninguém
   disponível, é Game Over — ver seção 2.3.

## 2. Decisões travadas

### 2.1 Sem entidade "treinador" — `Player` volta a ser a criatura

Reverter significa desfazer exatamente a separação que o `PIVOT_TREINADOR.md §3.7`
introduziu: `Player` para de usar `TrainerStats` e volta a derivar `maxHealth`/`speed`/
`shieldMax` de `creatureData.stats` (`BaseStats.maxHp`/`speed`/`defesa`), do mesmo jeito
que era antes do pivô anterior. `BaseStats.shieldMax` (`defesa * 2.0`) está comentado em
`base_stats.dart:17` — descomentar.

`TrainerStats` (`player/trainer_stats.dart`) é removido inteiro: nenhum dos seus campos
sobrevive de forma independente — `maxHealth`/`speed`/`shieldMax` voltam a vir da
criatura, e `captureRange` some junto com a captura (seção 2.4).

Consequência direta: **cada criatura do grupo tem sua própria vida/velocidade/escudo**,
não um valor fixo compartilhado. Isso já é o que o banco (seção 2.3) precisa de qualquer
forma — sem isso não haveria "vida da criatura X enquanto está no banco" para curar.

### 2.2 `Companion` sai inteiro; `AbilityUser`/`MovementHost` ficam

`Companion` (`creatures/companion.dart`) é apagado por completo: `CompanionPostura`,
`CompanionBehavior` (também sai de `CreatureData`, `creature_data.dart:18` e `:57`),
`_updateAimAndFire`, `_updateMovement`/`_updateOrbital`, o leash, a barra de vida
desenhada acima do sprite. Não sobra IA de criatura nenhuma — o jogador é a única fonte
de decisão de novo.

`AbilityUser` (`creatures/ability_user.dart`) e `MovementHost`
(`creatures/movement_host.dart`) **não saem** — são mixins que já foram extraídos
justamente para não depender de uma classe concreta (ver `PIVOT_TREINADOR.md §3.1/§3.2`).
`Player` continua implementando `AbilityUser` (já implementa hoje). `MovementHost` volta
a servir só a `Enemy`, como antes do `Companion` existir — nenhuma mudança nele.

As 34 habilidades (`creatures/abilities/`) não mudam: já recebem `AbilityUser` genérico,
não `Player` nem `Companion` especificamente. `ability2` volta a ser chamada de verdade
(ver 2.5) — o dado sempre existiu em `CreatureData`, só ninguém a executava.

### 2.3 Grupo de três com banco — a troca central deste pivô

Esta é a peça sem precedente no jogo antigo (que nunca teve grupo, nem troca), e a mais
fácil de errar. Decisão: **reaproveitar o sistema de bolso/cura que já existe**
(`CreaturesRogueGame.companionPocketed`/`companionSavedHealth`/
`curaBolsoFracaoPorSegundo`, `PIVOT_TREINADOR.md` checklist) em vez de inventar um novo.
Ele já resolve exatamente o problema de "criatura fora de campo, guardando uma vida
salva, curando uma fração por segundo" — só que hoje serve para o companion que
desmaiou ou foi recolhido manualmente. Vira o banco do grupo:

- **Slot ativo vs banco.** `companionAtivoIndex` (já existe) passa a apontar para qual
  slot do grupo é a criatura **que o `Player` está sendo agora**, não mais qual
  `Companion` recebe override.
- **Sem cura passiva no banco — emenda do usuário, pós-implementação.** A versão original
  desta seção previa curar uma fração de vida por segundo no banco
  (`curaBolsoFracaoPorSegundo`) e gatilhar disponibilidade por um piso de 30% pra
  compensar (uma criatura que acabou de desmaiar já estaria "curada o bastante" no frame
  seguinte, sem piso). O usuário decidiu que não quer cura nenhuma: **"disponível" é só
  "tem dono e vida `> 0`"**. A vida salva de um slot fica congelada exatamente como estava
  quando ele saiu do banco — só muda de novo quando a criatura volta a campo (recebe a
  vida salva de volta) ou desmaia de novo lá fora (zera). Sem piso, sem timer, sem `update`
  nenhum tocando `companionSavedHealth` fora de troca/desmaio.
- **Vida zerada em combate → troca IMEDIATA.** Mesmo gatilho de hoje (`Companion.takeDamage`
  chamando `pocketarSlot`), só que agora é `Player.takeDamage` chamando
  `CreaturesRogueGame.pocketarSlotAtivo()`: salva a vida (zero), entra no banco, e o jogo
  troca a ativa NA HORA para o primeiro outro slot **disponível** (regra acima — vida
  `> 0`), sem esperar nada curar (não cura mais).
- **Sem ninguém disponível → Game Over.** Se nenhum outro slot do grupo tem vida `> 0`
  (vazio, ou já derrotado), dispara o mesmo fluxo de `_handleGameOver` que hoje existe
  (`Player.onDeath`/`CreaturesRogueGame._handleGameOver`) — sem mudança nele. Ou seja:
  Game Over só quando as três criaturas do grupo já foram derrotadas.
- **Troca voluntária.** Tocar o retrato de um slot **disponível** (regra acima) chama a
  mesma rotina de troca (a ativa atual vai para o banco com a vida que tinha NA HORA, o
  slot tocado assume). Tocar um slot vazio ou já derrotado (vida 0) não faz nada — mesma
  regra que `Hud`/`CompanionPortraitIndicator` já aplicam para slot vazio.
- **Sem restrição de quando trocar** — a qualquer momento, inclusive em combate, igual
  ao toque no retrato hoje. Simplificação deliberada: uma restrição "só entre salas"
  exigiria um estado novo de bloqueio que nada mais no jogo tem. Se jogar mostrar que
  trocar em combate é forte demais (evitar dano trocando para a criatura de fora bem na
  hora do golpe), é ajuste de saldo (ex.: cooldown de troca), não de arquitetura — revisar
  depois do primeiro playtest.

**Como a troca troca o `Player` de verdade** — o ponto mais delicado da seção. `Player`
**não é recriado** ao trocar (diferente de como `Companion` é recriado hoje em
`liberarSlot`). Motivo: `RoomComponent` guarda `player:` como campo `final` no construtor
(mesmo ponto que `PIVOT_TREINADOR.md §3.7` já sinalizou sobre ordem de construção) — toda
sala já gerada na run aponta para a instância antiga. Recriar o `Player` deixaria todo
`RoomComponent` já montado com uma referência morta (porta/trava de sala para de
reconhecer o jogador). Antes da fase 4, vale conferir se mais algum componente guarda
referência direta ao `Player` esperando que ela nunca mude (`BlindOverlay`, `MinimapHud`
— ver Armadilhas).

Em vez de recriar, `Player` ganha um método `trocarCriatura(CreatureData nova,
{required double vidaSalva})` que **muta a instância existente**. Isso é mais do que
trocar `creatureData` e recarregar um sprite — `Player.onLoad` deriva SEIS coisas dele:
`visual` (`spritePath`), `shieldVisual` (bolha nas cores da criatura), `playerHitbox` e
`physicsHitbox` e a sombra (todos dimensionados por `hitboxSize`), `_moveAnimator` (hoje
fixo em `MovementAnimation.caminhada`, `player.dart:546` — precisa virar
`creatureData.moveAnim`), e o ramo `isAirborne`/`floatOffset` de `moveAnim ==
MovementAnimation.flutuar` (desloca hitbox e escudo). `_moveAnimator` e
`_visualBasePosition` são `late final` hoje — não dá para só reatribuir; viram campos
mutáveis, e o corpo de `onLoad` que monta essas seis peças precisa virar um método
próprio (ex.: `_montarVisualEHitbox()`), chamado tanto por `onLoad` quanto por
`trocarCriatura`: remove os componentes visuais/hitbox antigos (`removeFromParent`),
monta os novos a partir da `creatureData` atual. Zera cooldowns/knockback/esquiva/
escudo-bolha (estado de combate não atravessa a troca — a criatura que sai leva o dela
salvo só como vida, o resto é descartado, mesma regra que hoje vale para o `Companion`
recriado do bolso). O carregamento do sprite é assíncrono (mesmo `PaletteSwapper` de
sempre) — ver seção 4 sobre qual chave de cache ele usa. Posição, sala atual, câmera,
`onDeath` — nada disso muda, porque o componente é o mesmo.

### 2.4 Captura sai agora; substituto fica para depois

O laço inteiro (`PIVOT_TREINADOR.md §4`, fase 6) é removido nesta rodada, não adaptado.
Arquivos que saem por completo:

- `game/overlays/capture_swap_overlay.dart`
- `game/components/UI/capture_button.dart`
- `game/components/creatures/capture_lasso_visual.dart`

Trechos que saem de arquivos que ficam:

- `player.dart`: `startCapture`/`cancelCapture`/`_updateCapture`/
  `_encontrarAlvoCaptura`/`_paredeEntreCaptura`/`_completarCaptura`, `_capturaAlvo` e
  companhia, `captureOrbitRadius`/`captureHpFraction`, o hook em `takeDamage` que cancela
  o laço, a tecla C em `onKeyEvent`.
- `trainer_stats.dart`: sai junto com a classe inteira (seção 2.1).
- `creatures_rogue_game.dart`: `capturarCriatura`, `resolverTrocaCaptura`,
  `capturaPendente`, a montagem do `CaptureButton` em `_setupActionButtons`, o
  `onCaptureHoldChanged` em `_setupGestureControls`.
- `enemy.dart`: `enraizarParaCaptura`/`enraizadoPeloLaco` e o `if (enraizadoPeloLaco)`
  em `takeDamage` — nada mais depende de enraizar um inimigo.
- `main.dart`: o registro `'CaptureSwap': (context, game) => CaptureSwapOverlay(...)`
  em `overlayBuilderMap`.

Duas passivas foram construídas em cima do gancho de captura e ficam sem propósito:
`creatures/passives/fumaca_ao_lacar.dart` (Caranguejo Ermitão) e
`creatures/passives/raizes_do_laco.dart` (Toco de Madeira). Os hooks que elas usam
(`Passive.aoIniciarLaco`, `Passive.reducaoDuranteLaco`, ver `passive.dart`) saem da
interface. **Decisão pendente, não deste pivô**: o que essas duas criaturas ganham no
lugar. Registrar como placeholder (passiva neutra) por ora — redesenhar a passiva de
cada uma é trabalho separado, não travar este pivô nisso.

### 2.5 Habilidade B volta a existir

`Companion` roda só `ability1` (`PIVOT_TREINADOR.md`, pedido do usuário na época,
`companion.dart:432`). Sem `Companion`, essa restrição não faz mais sentido: `Player`
volta a executar as duas, cada uma no seu botão/cooldown, exatamente como o modelo antigo
fazia (`Ability.execute(AbilityUser user, Vector2 dir)`, `AbilityTipo` decide o ícone).

Estrutura por habilidade, uma vez que `Companion._updateAimAndFire` já tinha resolvido o
padrão (mira travada por `AbilityTarget.enemyDir`/`plrDir`, cooldown, `canExecute` para o
gate de bomba) — só troca "dispara sozinho quando o cooldown zera" por "dispara quando o
jogador aperta o botão E o cooldown já zerou":

```
void _tryAbility(Ability ability, ...) {
  if (cooldown > 0) return;
  if (!ability.canExecute(this)) return;
  ability.execute(this, direcaoTravada);
  cooldown = ability.cooldown * cdMult;
}
```

`lockedAb1Direction`/`lockedAb2Direction` (hoje inertes em `Player`, `player.dart:127-128`)
voltam a ser calculadas de verdade, a partir da própria posição — mesma lógica que
`Companion._updateAimAndFire` já tinha (`enemyDir` = inimigo mais próximo na sala,
`plrDir` = direção que o sprite está olhando).

**`cdMult` precisa voltar para `Player`.** O checklist do `PIVOT_TREINADOR.md` registra
que `cdMult` foi removido de `Player` e que o power-up `fireRateUp` passou a escrever em
`companion?.cdMult` — sem `Companion`, essa escrita fica órfã e o projeto não compila.
Restaurar o campo em `Player` e repor `fireRateUp` (e qualquer outro power-up que tenha
seguido o mesmo padrão — checar `grep -rn "companion?\." lib/game/components/items`)
apontando para ele de novo.

### 2.6 Alvo dos inimigos — nada a fazer

`Enemy.currentTarget` (`enemy.dart:172`) já é só `playerTarget`, sempre. O item aberto no
checklist do `PIVOT_TREINADOR.md` ("aggro por proximidade entre treinador e companion
nunca foi implementado") fica **obsoleto**, não pendente: sem `Companion` no mundo, não
há "companion" para o inimigo escolher — o comportamento atual já é exatamente o que este
pivô precisa, de graça.

### 2.7 Botões e gestos

Orçamento de ações do jogador volta a ser: habilidade A, habilidade B, esquiva pessoal
(`Player.dodge`, ver 3 — fica, é sistema novo desde o pivô anterior). Sem captura nem
recolher/liberar grupo (não existe mais "grupo fora vs dentro", só "ativa vs banco",
trocado pelo retrato — sem botão dedicado). Três ações, três slots — cabe sem disputa,
diferente do aperto que `PIVOT_TREINADOR.md §2.1.1` documentou.

`_setupActionButtons` volta a montar dois `AbilityButton` (A e B, lendo
`creatureData.ability1/2.tipo`) mais o botão de esquiva que já existe hoje.
`RecallButton` sai (nada mais "recolhe o grupo" em massa).

Esquema de gestos (`GestureActionArea`) precisa de redesenho: hoje resolve três ações
(captura-hold, swipe-up, swipe-down) que não são mais as três certas. O esquema
pré-`PIVOT_TREINADOR.md` era mais simples (toque parado = habilidade 1, arrastar =
habilidade 2, sem esquiva — ela não existia ainda). Com esquiva para encaixar, é a mesma
classe de problema que `PIVOT_TREINADOR.md §2.1.1` resolveu para os botões. **Decisão
adiada para a fase de implementação correspondente** (seção 6, fase 4) — não travar o
resto do pivô nisso; esquema de botões é o caminho principal, gestos podem ficar quebrados
por uma fase sem bloquear o resto.

## 3. Sistemas preservados — não tocar

Construídos depois do `PIVOT_TREINADOR.md`, independentes do modelo de controle. Nenhuma
mudança esperada:

- `l10n/` inteiro (i18n).
- `game/audio/` + `game_settings.dart` (áudio e opção de desligar som).
- `game/overlays/pause_overlay.dart`, `settings_overlay.dart` — o retrato de equipe em
  `pause_overlay.dart` lê `game.companionCreatures`/`companionPocketed`/
  `companionAtivoIndex` (campos da própria `CreaturesRogueGame`, não da classe
  `Companion`), que continuam existindo com o mesmo papel de "grupo/banco" — só o rótulo
  mental muda de "companion" para "integrante do grupo".
- `game/components/enemies/` inteiro (IA, spawns, `boss_registry.dart`, vida/dano
  tunados no `PIVOT_TREINADOR.md`).
- `game/components/projeteis/` (colisão projétil-projétil, bombas, explosões).
- `game/components/map/` (geração de dungeon, salas, portas).
- `Player.dodge` e a barra de esquiva sob o sprite (`player.dart:268-304`, `:493-509`) —
  sistema novo desde o pivô anterior, sem relação com o modelo de controle, fica como
  está.
- `Player.passivasAtivas`/`Passive` (exceto os dois hooks de laço, seção 2.4) — passivas
  do grupo continuam valendo enquanto a criatura estiver no grupo, banco ou fora dele.
- `Hud`: barras de vida/escudo do `Player` (já lêem `player.maxHealth`/`shieldMax`, que
  passam a vir de novo de `creatureData` — sem mudança de código, só de onde o valor
  nasce) e `CompanionPortraitIndicator` × 3 (vira indicador de slot do grupo — mesmo
  componente, ver seção 4).
- Itens/consumíveis, loja, minimapa, boss reveal/health bar.

## 4. Mudanças em sistemas que ficam, mas precisam de ajuste

- **`CompanionPortraitIndicator`** (`UI/companion_portrait_indicator.dart`) fica, mas
  `posturaAtual`/`CompanionPostura` some do seu contrato (não há mais postura). O marcador
  vermelho/azul de canto (`PIVOT_TREINADOR.md`, postura não-`seguir`) sai; o resto —
  retrato, contorno de ativa, cinza de cura no banco — não muda.
- **`Hud`** perde `companionOf`/`ability1CooldownFraction` (que hoje leriam o
  `Companion` ativo, comentados desde a simplificação para uma habilidade só —
  `hud.dart:148-153`); ganha de volta os dois `AbilityCooldownIndicator` (A e B), lendo
  `player.ability1CooldownFraction`/`ability2CooldownFraction` diretamente — o padrão que
  já existia antes do `PIVOT_TREINADOR.md`.
- **`DamageableByEnemy`** e os três pontos de dano que testam o supertipo comum
  (`projectile.dart`, `explosion_hitbox.dart`, `bomb.dart` — ver `PIVOT_TREINADOR.md
  §3.3`) não precisam mudar: `Player` continua implementando `DamageableByEnemy`,
  `Companion` só deixa de existir como outro implementador. Nenhum `is Companion`
  encontrado nesses três arquivos para limpar.
- **`_preloadCombatSprites` NÃO perde o terceiro bloco por criatura.** A variante "sem
  `whiteReplacement`" (`creatures_rogue_game.dart:735-739`), hoje comentada como "forma
  companion", é exatamente a chave de cache que o `Player` passa a usar para o próprio
  sprite (seção 1, item 1 — mesmo `imagePath`/cores que `Companion.onLoad` já usava, sem
  `whiteReplacement`). Fica, só o comentário muda: não é mais "sprite do companion", é "
  sprite da criatura ativa, agora é o próprio `Player`". Apagar esse bloco faria a
  PRIMEIRA troca de criatura em pleno combate gerar textura nova na hora (a travadinha
  que o preload existe para evitar). As outras duas variantes (inimigo/boss e escudo do
  treinador, ambas com `whiteReplacement`) continuam sem mudança — o escudo do `Player`
  já usa a mesma chave hoje.
- **Fates dos campos hoje em `CreaturesRogueGame` que falam de "companion":**
  - `companions` (`List<Companion?>`) e o getter `companion` — **saem**, junto com o tipo
    `Companion`. Nada mais precisa de "qual componente está montado no slot".
  - `alternarRecuoGrupo` — **sai**. Não existe mais "grupo inteiro fora vs no bolso": só
    existe "ativa vs banco", e a troca é sempre de uma criatura por vez, pelo retrato.
  - `pocketarSlot` — **fica, adaptado**: passa a salvar a vida da criatura ATIVA (a
    troca lê `player.currentHealth`/`player.maxHealth`, não mais `Companion.currentHealth`)
    e não remove componente nenhum do mundo (o `Player` continua montado — quem sai é só
    o dado da criatura, não uma entidade).
  - `liberarSlot` — **sai como está** (recriava um `Companion`); a metade "entrar em
    campo" da troca passa a ser o próprio `trocarCriatura` (seção 2.3), chamado por
    quem hoje chamaria `liberarSlot`.
  - `companionCreatures`/`companionPocketed`/`companionSavedHealth`/
    `companionPocketFraction` — ficam, cobertos na seção 3 (preservados), continuam
    sendo o banco. `curaBolsoFracaoPorSegundo` **saiu** (emenda do usuário — seção 2.3):
    sem cura passiva, `companionSavedHealth` só muda em troca/desmaio, nunca em `update`.
  - `effects/companion_recall_effect.dart` e `effects/companion_revive_effect.dart` —
    **ficam, repropostos**: hoje tocam quando um `Companion` é recolhido/liberado; passam
    a tocar quando o `Player` troca para o banco / entra em campo a partir do banco (são
    efeitos posicionais de mundo, não dependem de `Companion` como tipo).
- **`nextLevel()`**: o trecho que preserva `Companion` ao trocar de andar
  (`child is! Companion`, `creatures_rogue_game.dart:1042`) sai — só `player` precisa
  sobreviver à faxineira agora. O reposicionamento de companions logo abaixo
  (`:1084-1086`) sai junto.
- **`startRun`**: a varredura de `whereType<Companion>()` (`:346`) sai; a criação do
  `companions[0]` (`:360-365`) sai — a run começa só com `player` e
  `companionCreatures[0] = creature` (o resto do grupo vazio, até a seção 5 existir).

## 5. Como o grupo ganha a segunda e a terceira criatura — criatura selvagem na sala da escada

Decisão travada pelo usuário: sem laço, sem minigame. Uma criatura aleatória aparece
parada na sala da escada do **quarto andar** de cada dungeon (o andar logo antes do
boss); encostar nela recruta na hora.

### 5.1 Onde "a sala da escada" já existe

Não precisa de `RoomType` novo nem de mudança no gerador. `RoomComponent._unlockRoom`
(`room_component.dart:307-322`) já adiciona `Stairs` toda vez que a sala `RoomType.boss`
(o beco sem-saída que `DungeonGenerator._assignSpecialRooms` sorteia) destranca — em
QUALQUER andar, não só no andar de boss de verdade (`isBossFloor`,
`currentFloor % andaresPorBoss == 0`). O que diferencia o andar de boss é só
`_spawnEnemies` (`:335-344`): com `bossBuilder` não nulo, essa sala vira a luta; senão,
"essa sala fica vazia e destranca na hora, sem briga" (comentário já existente no
código). O quarto andar (`currentFloor == andaresPorBoss - 1`, ou seja `4` com o valor
atual) é exatamente esse caso — sala da escada vazia, destrancada, sem risco nenhum.
Ponto de baixo atrito perfeito para plantar a criatura: o jogador não está em combate
quando a alcança.

### 5.2 Peças novas

Mesmo padrão que `bossBuilder`/`isBossFloor` já usa — nada de mecanismo novo, só mais um
`Function(Vector2 position)?` opcional passado para `RoomComponent`:

- **`RoomComponent`** ganha `final WildCreatureNpc? Function(Vector2 position)?
  wildCreatureBuilder`. Em `_unlockRoom`, logo depois de spawnar `Stairs`: se
  `data.type == RoomType.boss` e `wildCreatureBuilder` não é nulo, chama e adiciona o
  resultado (se não for `null`) numa posição que não brigue com a escada nem com a
  recompensa (`_spawnRecompensa` usa `height/2 + 28`, `_spawnBoss` usa `height/2 - 24`
  quando existe — a criatura usa `height/2 - 28`, livre).
- **`CreaturesRogueGame`** passa `wildCreatureBuilder: currentFloor == andaresPorBoss - 1
  ? _buildWildCreature : null` na construção de `RoomComponent`, nos dois lugares que já
  passam `bossBuilder` (`startRun` e `nextLevel`). `_buildWildCreature(Vector2 position)`:
  - Sem slot livre em `companionCreatures` (grupo já com três) → devolve `null`, a sala
    fica vazia como qualquer andar não-4 — sem prompt, sem fila de espera, mesma filosofia
    de "sem drama" que `PIVOT_TREINADOR.md §4.3` tinha descartado para o laço, mas que
    aqui é a opção certa: não há decisão nenhuma para o jogador tomar, só nada para
    encontrar.
  - Com slot livre, sorteia uma `CreatureData` de `CreatureRegistry.all` **excluindo** as
    que já estão em `companionCreatures` (comparar por `.id`) — sem duplicata no grupo.
    Devolve `WildCreatureNpc(position: position, creatureData: sorteada)`.
  - Nova classe `WildCreatureNpc` (`creatures/wild_creature_npc.dart`): parada, sem IA de
    combate nenhuma (não estende `Enemy`, não implementa `DamageableByEnemy`) — só um
    sprite (mesma chave de cache sem `whiteReplacement` que `Player` agora usa, seção 4)
    e um `RectangleHitbox` passivo. `onCollisionStart` com `other is Player` chama
    `gameRef.recrutarCriaturaSelvagem(creatureData)`; se devolver `true`, toca o mesmo
    efeito branco que hoje celebra `liberarSlot` (`CompanionReviveEffect`, reproposto —
    seção 4) e se remove.
  - `CreaturesRogueGame.recrutarCriaturaSelvagem(CreatureData creature)`: acha o primeiro
    slot livre em `companionCreatures`, preenche `companionCreatures[slot] = creature`,
    `companionSavedHealth[slot] = creature.stats.maxHp` (entra com vida cheia),
    `companionPocketed[slot] = true` (entra no BANCO, não vira a ativa automaticamente —
    o jogador troca pelo retrato quando quiser, mesma UI que já existe). Devolve `true`
    em sucesso.

### 5.3 Fora de escopo mesmo assim

Sem confirmação/prompt antes de recruitar — encostar já basta, por pedido explícito de
simplicidade. Se jogar mostrar que um recrutamento sem querer (passando correndo perto)
incomoda, o ajuste é de saldo (raio do hitbox, ou um segundo de "tempo parado perto"),
não de arquitetura. Nada de raridade/variedade por andar, nada de escolher entre duas
opções — uma criatura, um andar, aleatória, ponto.

## 6. Fases de implementação

Ordem por risco, cada fase termina com o jogo rodando — mesmo princípio do
`PIVOT_TREINADOR.md §5`.

### Fase 0 — Captura fora

Remover tudo da seção 2.4 primeiro, isolado: reduz superfície antes de mexer em
`Player`/`Companion`, e é reversível de forma independente (dá para confirmar que o resto
do jogo roda sem captura antes de tocar em controle). Placeholder nas duas passivas
afetadas (seção 2.4).

### Fase 1 — `TrainerStats` fora, `Player` deriva de `creatureData` de novo

Seção 2.1. Ao fim desta fase o `Player` já tem vida/velocidade/escudo por criatura de
novo, mas ainda sem grupo nem habilidades diretas — jogo roda igual a antes desta fase
(uma única criatura, sem trocar).

### Fase 2 — Habilidades diretas, `Companion` fora

Seções 2.2 e 2.5 juntas (não dá para tirar `Companion` sem `Player` já saber executar as
duas habilidades sozinho — o jogo ficaria sem ofensiva no meio do caminho). HUD ganha os
dois indicadores de cooldown de volta (seção 4). **Jogar antes de seguir** — é aqui que
se confirma que o controle direto voltou a sentir como o modelo antigo.

### Fase 3 — Botões e gestos

Seção 2.7. Botões primeiro (menor risco, `AbilityButton` já é genérico); gestos depois,
com o redesenho do esquema de 3 ações.

### Fase 4 — Grupo e banco

Seção 2.3 inteira: `trocarCriatura`, troca voluntária pelo retrato, vida zerada em
combate mandando para o banco e trocando automaticamente, Game Over só no grupo inteiro
esgotado. **Jogar antes de seguir** — maior peça nova deste pivô, a que mais precisa de
playtest. Nesta fase o grupo ainda só tem a criatura inicial (slots 1/2 vazios, a
criatura selvagem da seção 5 ainda não existe) — dá para testar a troca e o desmaio
simulando manualmente uma segunda criatura no slot 1 (atribuição direta em código,
descartável, só para o teste, sem esperar a fase 5).

### Fase 5 — Criatura selvagem na sala da escada

Seção 5: `WildCreatureNpc`, `RoomComponent.wildCreatureBuilder`,
`CreaturesRogueGame._buildWildCreature`/`recrutarCriaturaSelvagem`. Depende da fase 4 já
estar de pé (recrutar só faz sentido com banco/troca funcionando). Ao fim desta fase o
grupo de três é alcançável jogando, sem hack de teste nenhum. **Jogar até o quarto
andar** — confirma se a sala vazia é reconhecível como "achei uma criatura" (posição/
sprite legível) e se recrutar sem querer, de passagem, incomoda (ver seção 5.3).

## 7. Armadilhas

**`RoomComponent.player` é `final`.** Já coberto na seção 2.3 — é o motivo de
`trocarCriatura` mutar a instância em vez de recriar. Vale revisar se mais algum
componente guarda referência direta ao `Player` esperando que ela nunca mude
(`BlindOverlay`, `MinimapHud` — checar antes da fase 4).

**`Player.danoMult` é `static`.** `PIVOT_TREINADOR.md §3.7` já decidiu que upgrade de
dano vale para o grupo inteiro de uma vez — com `Player` mutando de criatura em vez de
existirem três instâncias simultâneas, isso deixa de ser uma decisão de design e vira
consequência natural (o multiplicador é do jogador, não da criatura, e só existe um
`Player`). Nenhuma mudança necessária, só deixou de ser ambíguo.

**Estado de combate não atravessa a troca.** `shieldHits`/`damageReduction`/
`speedLocked`/cooldowns — tudo isso é `AbilityUser` genérico, zerado em
`trocarCriatura` (seção 2.3). Um buff ativo na criatura ativa morre se ela for trocada
para o banco no meio do efeito. Aceitável como primeiro corte; se jogar mostrar que troca
vira uma forma barata de "limpar" um debuff ruim (ex.: lentidão), é ajuste de saldo, não
retrabalho de arquitetura.

**Trocar de criatura pode mudar o `physicsHitbox` no meio de uma porta.** Consequência
direta de mutar a instância em vez de recriar (seção 2.3): `_checkCameraTransition`/
`_prendeJogadorNaSala` leem `physicsHitbox.toAbsoluteRect()` contra um limiar fixo de 8px
para decidir troca de sala. Trocar para uma criatura com `hitboxSize` bem maior enquanto
o jogador está parado numa porta é um caso novo que o modelo antigo (hitbox fixo por run)
nunca precisou tratar — verificar depois de implementar `trocarCriatura`, mesmo item da
revisão de `BlindOverlay`/`MinimapHud` acima.

**`bombsAmount` NÃO está infinito** — `player.dart:886-891` já decrementa de verdade
(`if (bombsAmount <= 0) return; bombsAmount--;`), e o checklist do `PIVOT_TREINADOR.md`
confirma isso reativado na fase 1 daquele pivô. O que continua faltando é só a exibição
na Hud: `hud.dart:266-268` (contagem de bombas) está comentada. Sem relação com este
pivô, mas fica registrado para não confundir com bug.

**Passivas de laço (seção 2.4) ficam com hook morto até serem redesenhadas.** Não é bug
deste pivô — é dívida registrada de propósito, para não bloquear a captura saindo hoje.

## 8. Checklist

- [x] Fase 0: captura removida (arquivos, trechos, registro em `main.dart`), placeholder
  nas duas passivas afetadas
- [x] Fase 1: `TrainerStats` removido, `Player` deriva stats de `creatureData`,
  `BaseStats.shieldMax` descomentado, sprite volta a ser `creatureData.spritePath`
  (não mais `'actors/plr.png'`)
- [x] Fase 2: `Companion` removido, `Player` executa `ability1`/`ability2` direto,
  `lockedAb1Direction`/`lockedAb2Direction` calculadas de novo, Hud com os dois
  indicadores de cooldown, `cdMult` restaurado em `Player` e `fireRateUp` repontado
  (`grep -rn "companion?\." lib/game/components/items` só achou o `fireRateUp` já
  corrigido — nenhum outro power-up órfão)
- [x] **Jogar fase 2** — smoke test automatizado (build web, `flutter analyze` sem erros,
  run completo no navegador): as duas habilidades disparam pelos botões corretos, com o
  ícone certo e cooldown visível na Hud (`ver captura de tela`), esquiva com o rastro da
  passiva do Torchmin, movimento por joystick. Sensação subjetiva de "modelo antigo" ainda
  pede um playtest humano de verdade — o smoke test confirma que funciona, não que está
  bem tunado
- [x] Fase 3: botões A/B/esquiva remontados, `RecallButton`/`CaptureButton` fora,
  gestos redesenhados (2 habilidades + esquiva) — `AbilityButton` também ganhou o ícone
  dinâmico (`AbilityIcons.of(tipo())`) que faltava (antes sempre desenhava o ícone de
  esquiva, morto desde antes deste pivô)
- [x] Fase 4: `Player.trocarCriatura` (visual/hitbox/animator/shield reconstruídos, não só
  o sprite), troca voluntária pelo retrato, banco automático (imediato) ao zerar vida,
  Game Over só no grupo esgotado, campos `companions`/`companion`/`alternarRecuoGrupo`
  removidos e `pocketarSlot`/`liberarSlot` adaptados (ver seção 4)
- [x] **Achado no primeiro teste real, com duas criaturas no grupo**: encostar na
  criatura selvagem preenchia os DOIS slots vazios com a mesma criatura, não um. Causa:
  `Player` tem dois hitboxes ativos (`playerHitbox`, `physicsHitbox`); o hitbox passivo
  do `WildCreatureNpc` colide com os dois, disparando `onCollisionStart` duas vezes antes
  de `removeFromParent()` (que só surte efeito no fim do frame) tirar o NPC do mundo.
  Fix: `WildCreatureNpc._recrutado`, uma trava booleana que ignora qualquer colisão depois
  da primeira bem-sucedida
- [x] **Emenda do usuário, pós-playtest**: sem cura passiva no banco (`curaBolsoFracaoPorSegundo`
  removido, junto com o `update` que o usava) e sem piso de disponibilidade
  (`bancoDisponivelFracaoMinima` removido) — "disponível" volta a ser só vida `> 0`, e a
  troca ao desmaiar é imediata, não esperando nada curar. `CompanionPortraitIndicator`/
  `Hud` ajustados: o cinza do retrato agora é um retrato estático da vida salva, não uma
  barra enchendo com o tempo
- [ ] **Jogar fase 4** — a troca voluntária pelo retrato e a troca automática ao desmaiar
  já foram exercitadas com um grupo de duas de verdade (achado acima veio exatamente
  desse teste), mas falta confirmar: Game Over disparando de verdade com as três
  derrotadas, e trocar parado numa porta (hitbox mudando de tamanho, ver Armadilhas)
- [x] Revisado `BlindOverlay`/`MinimapHud`: nenhum dos dois quebra com `trocarCriatura`
  — `BlindOverlay` só lê `player.cegoTimer`/`absolutePosition` (válidos com qualquer
  criatura), `MinimapHud` nem referencia `Player`. Segue faltando testar em jogo a troca
  parada numa porta (hitbox mudando de tamanho) — sem uma segunda criatura ainda, nada
  pra trocar
- [x] Fase 5: `WildCreatureNpc`, `RoomComponent.wildCreatureBuilder` (posição
  `height/2 - 28`, sem colidir com escada/recompensa/boss), `_buildWildCreature`
  (`null` sem slot livre, sorteio excluindo `.id` já no grupo),
  `recrutarCriaturaSelvagem` (entra no banco, vida cheia), efeito de recrutamento
- [ ] **Jogar até o quarto andar** — não testado: chegar ao andar 4 exige atravessar e
  limpar ~3 andares de dungeon gerada, fora do alcance de um smoke test automatizado
  nesta rodada. Falta confirmar em jogo: sala reconhecível, recrutar por engano incomoda,
  e a troca funcionando com uma criatura recrutada de verdade (não simulada)
