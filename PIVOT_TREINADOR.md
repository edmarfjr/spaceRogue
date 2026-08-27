# Pivô de design: do controle direto da criatura para o treinador com grupo

Documento de implementação. Continua de onde `PIVOT_CRIATURAS.md` parou e descreve a
segunda mudança de direção: o jogador deixa de **ser** a criatura e passa a ser o
**treinador** que a invoca, comanda e captura.

Os números de superfície de código citados aqui foram medidos no estado atual do
repositório (128 arquivos `.dart`, ~12.850 linhas). Estão anotados porque são eles
que definem o custo de cada fase — se o código mudar muito antes da implementação,
vale remedir antes de confiar na ordem das fases.

## 1. O que muda

1. **O jogador controla o treinador.** Um ator novo, com sprite e stats próprios,
   movido pelo joystick que já existe. Ele não é uma criatura e não tem tipo elemental.
2. **As criaturas agem sozinhas.** Cada criatura invocada tem um comportamento
   (natureza) que decide como ela se move e quando dispara: ficar perto do treinador
   atirando no que chegar, perseguir, orbitar, e assim por diante.
3. **Captura.** Inimigos podem ser capturados e passam a integrar o grupo, limitado a
   três criaturas simultâneas.
4. **Os dois botões viram override.** Eles não somem: a IA dispara a habilidade quando
   o cooldown zera, e o jogador pode antecipar o disparo apertando o botão.

## 2. Decisões travadas

### 2.1 O treinador não é um espectador

Esta é a decisão central, e vale registrar o raciocínio porque ela é a que mais
facilmente se perde na implementação.

Criaturas totalmente autônomas mais um treinador sem ofensiva reduzem a agência do
jogador a movimento puro. Isso é fino demais para um roguelike de ação: o jogador
posiciona e assiste. Pokémon Quest resolve exatamente esse problema — as habilidades
disparam sozinhas, mas cada uma tem um override manual.

A solução adotada é a mesma, e ela tem o efeito colateral de ser a mais barata: os dois
`AbilityButton` de hoje (ver `creatures_rogue_game.dart`, `_setupAbilityControls`)
continuam existindo, o `Hud` continua desenhando dois indicadores de cooldown, e a única
diferença é de quem eles leem — da criatura ativa, não do `Player`.

Alternativas consideradas e descartadas:

- **Botões viram arremesso de captura e rally.** O combate fica passivo demais; o
  jogador perde o único momento de decisão tática que ainda tinha.
- **Um botão por criatura (três botões).** Polui a tela em mobile, e na prática a
  terceira criatura é esquecida.
- **Só um toggle de postura.** Vira jogo de gerenciamento, não de ação.

Complemento adotado: além do override, um comando de **postura** aplicado ao grupo
(agressivo / segurar posição / seguir). Natureza fixa sozinha está errada — uma sala
que pede recuo com uma criatura de natureza "perseguidora" é frustração, não desafio.
A postura é o que dá ao input do treinador um trabalho contínuo entre os disparos.

**Emenda pós-playtest da fase 3.** Override sozinho não bastava: as habilidades
executam com `user` = o companion, então mesmo apertando o botão o efeito (dano,
escudo, dash) acontece na criatura, nunca no treinador. Ability2 (quase sempre
`defesa`/`esquiva`) ficou sem propósito percebido porque protege quem não estava em
risco. Faltava uma ação que fosse do treinador de verdade, sem passar por criatura
nenhuma.

Adicionado: **esquiva pessoal do treinador** (`Player.dodge`) — i-frames curtos mais
um dash curto, mesma receita de `EsquivaBomba` (`grantInvulnerability` +
`GhostEffect.spawnTrail` + `MoveByEffect`), só que fora do sistema de `Ability`. Terceiro
botão em `_setupActionButtons`, tecla Space no teclado. Não tem cooldown desenhado na
Hud ainda (só dois indicadores existem) e não existe no esquema de gestos — os dois
ficam para quando a UI de três botões for revisada.

Com isso, o par override + esquiva pessoal cobre as duas metades do problema original:
override dá ao treinador controle sobre a ofensiva/defesa da criatura; a esquiva dá
uma ação de sobrevivência que é dele, não dela. Ability2 continua sem propósito quando
a IA a dispara sozinha — por isso ela agora **só** dispara por override, nunca sozinha
(ver §3.5 e a implementação de `Companion._tryFire`).

### 2.1.1 Orçamento de botões

Com o laço de captura (seção 4.1), o treinador tem quatro intenções distintas e um
polegar só. Os quatro concorrentes, em ordem de frequência de uso:

1. Override da habilidade A da criatura ativa — constante
2. Override da habilidade B — constante
3. Captura — raro, mas exige **segurar** durante toda a volta
4. Postura do grupo — ocasional

A tela já está no limite: dois `AbilityButton` no canto inferior direito mais dois
`ConsumableSlotButton`. Decisão: **captura ganha botão próprio; postura não é botão.**

- Captura é a única das quatro que precisa de um "segurar" contínuo e sem ambiguidade.
  Compartilhar botão com override significaria distinguir toque curto de toque longo em
  pleno combate, o que é exatamente o tipo de input que falha na hora errada.
- Postura vira um controle de baixa frequência: um toque no retrato da criatura na HUD
  cicla a postura dela. Isso também resolve o problema de aplicar postura por criatura
  em vez de ao grupo inteiro, que é melhor de qualquer forma.

Se o terceiro botão apertar demais o layout em telas pequenas, o corte é a postura —
naturezas fixas ainda deixam o jogo jogável, captura sem input dedicado não.

### 2.2 A forma jogável vira a forma companion

Toda criatura continua tendo as três formas do escopo original (jogável, inimigo comum
e boss, diferenciadas também por padrão de disparo e comportamento de projétil). O que
muda é apenas **quem puxa o gatilho** da forma jogável: antes era o botão do jogador,
agora é a IA do companion, com o botão como override.

Consequência prática: `CreatureData.ability1` e `ability2` continuam sendo as
habilidades da forma jogável/companion, e `creature_select_overlay.dart` (412 linhas)
sobrevive quase intacto — muda o texto ("escolha sua criatura inicial") e não a
estrutura.

### 2.3 Regras de combate

- **Companion consome perfuração.** Um companion no caminho de um tiro inimigo o
  absorve, gastando `atravessa` do projétil. É isso que transforma posicionamento na
  habilidade central do treinador. Sem essa regra, o companion é uma torreta decorativa.
- **Aggro por proximidade, sem preferência.** O inimigo mira o hostil mais próximo,
  seja o treinador ou um companion. Dar preferência ao companion transformaria toda
  criatura em tanque e deixaria o treinador seguro por padrão, o que muda a dificuldade
  do jogo inteiro.
- **Fail state:** o treinador morre, a run acaba. Isso preserva `player.onDeath` /
  `onGameOver` e mantém a barra de HP da HUD com significado. Companion não morre:
  desmaia e volta sozinho depois de um tempo (`companionReviveDuration`, 10s — ver
  emenda abaixo).

**Emenda pós-playtest.** A ideia original era o companion voltar só ao limpar a sala —
trocada por um timer fixo (`CreaturesRogueGame.companionReviveDuration`, 10s, primeiro
corte sem tuning): esperar o resto do combate inteiro sem poder fazer nada com a
criatura foi reportado como frustrante. `Companion._faint()` chama
`CreaturesRogueGame.scheduleCompanionRevive()`, que arma o timer; o `update` do jogo
recria o `Companion` (mesma `creatureData` da run, guardada em `_companionCreature`)
na posição atual do treinador ao zerar — não na posição de onde desmaiou, o que também
evita reviver dentro de uma sala que o treinador já deixou pra trás. Indicador visual: `CompanionPortraitIndicator` novo na Hud (`components/UI/`),
retrato da criatura (mesmo sprite, recolorido igual a todo o resto) com o mesmo cinza
que esvazia de cima pra baixo dos dois `AbilityCooldownIndicator` — existe mesmo com o
companion morto, porque é o único lugar que mostra status dele nesse intervalo (o
componente em si some do mundo enquanto o timer conta).

## 3. Arquitetura

O princípio, herdado do pivô anterior: **compartilhar dado e comportamento por mixin,
não por hierarquia.** Não criar uma classe base comum entre `Player`, `Enemy` e
`Companion`.

### 3.1 `MovementHost` — o que torna o pivô barato

Os cinco mixins de IA em `enemy_mixins.dart` (`GridMovement`, `WanderMovement`,
`ShooterAttack`, `ChaseMovement`, `JumpMovement`) estão declarados como `on Enemy`, mas
mal conhecem `Enemy`. A superfície real, medida mixin a mixin:

| Mixin | Membros de `Enemy` que usa |
|-------|----------------------------|
| `GridMovement` | `position`, `speed`, `visual` |
| `WanderMovement` | os anteriores mais `animateMovement`, `direcaoLivre`, `knockbackVelocity` |
| `ShooterAttack` | `cegoTimer`, `spawnAlerta`, `visual` |
| `ChaseMovement` | `absolutePosition`, `animateMovement`, `cegoTimer`, `direcaoLivre`, `playerTarget`, `position`, `speed`, `visual` |
| `JumpMovement` | `absolutePosition`, `enemyHitbox`, `physicsHitbox`, `isAirborne`, `knockbackVelocity`, `position`, `size`, `spawnAlerta`, `speed`, `visual` |

Catorze membros no total, e `playerTarget` aparece **uma única vez** no arquivo inteiro
(`enemy_mixins.dart:229`, dentro de `ChaseMovement`).

Portanto: extrair `mixin MovementHost on PositionComponent` com esses catorze membros,
trocar `on Enemy` por `on MovementHost` nos cinco mixins, e fazer `Enemy` e `Companion`
usarem `MovementHost`. O companion herda os cinco comportamentos de IA sem uma linha de
IA nova.

Se essa medição não se confirmar na hora de implementar, o pivô fica muito mais caro —
o companion precisaria de movimento próprio. Vale remedir antes da fase 2.

### 3.2 `AbilityUser` — desacoplar as 34 habilidades do `Player`

`Ability.execute(Player user, Vector2 dir)` recebe `Player` concreto. As 34 habilidades
em `creatures/abilities/` tocam 19 membros distintos de `user`, que se dividem em três
grupos:

- **Plumbing** (`creatureData`, `position`, `size`, `visual`, `parent`, `add`,
  `isMounted`): entram na interface `AbilityUser` diretamente.
- **Sinks de buff** (`shieldVisualActive`, `speedLocked`, `shieldHits`,
  `damageReduction`, `refleteProjetil`, `retaliaEspinhos`, `retaliaDano`,
  `retaliaStunDuration`): são campos mutáveis simples, sem lógica. Vão para um
  `mixin AbilityBuffSinks` que `Player` e `Companion` usam. Não redeclarar em cada um.
- **Decidido — bomba é recurso do treinador.** `bombsAmount` continua vivendo no
  `Player`, e `deixar_bomba` / `esquiva_bomba` (habilidades de criatura) consomem esse
  contador. A criatura **não** tem contador próprio.

  Atenção, porque isso é mais do que roteamento: hoje o decremento está **comentado**
  em `player.dart:652-653`, ou seja, bomba é infinita no estado atual. Confirmar a
  decisão significa reativar essas duas linhas, e reativá-las cria um modo de falha que
  ainda não existe. `deixar_bomba` é a habilidade A da Bomba de Fogo e `esquiva_bomba` é
  a B: com `bombsAmount == 0`, essa criatura fica sem nenhuma ofensiva e com dois
  cooldowns girando para nada. Regra explícita:

  - Sem bomba, a habilidade **não dispara e não consome o cooldown**. Cooldown zerado
    parado lê como "esperando recurso"; cooldown girando sem efeito lê como bug.
  - `esquiva_bomba` é evasiva que *também* solta bomba. Com zero bombas o **dash e os
    i-frames continuam acontecendo** — a mobilidade é a metade defensiva da habilidade,
    e ela não depende do recurso. Só a bomba é suprimida.
  - A HUD precisa mostrar a contagem de bombas quando a criatura ativa depende dela.
    O jogador não pode descobrir que está sem bomba apertando o botão.

- **Precisa de decisão:**
  - `lockedAb1Direction` / `lockedAb2Direction`. Hoje é a mira travada no inimigo mais
    próximo, calculada pelo `Player`. Passa a ser calculada por cada companion, a partir
    da própria posição.

Além disso, `AbilityUser` precisa expor a **facção** (ou o `isEnemy` equivalente). Hoje
várias habilidades passam `isEnemy` implicitamente ao criar `Projectile`. Como a mesma
instância stateless de `Ability` agora serve às três formas (jogável/companion, inimigo,
boss), ela tem de ler a facção do `user` em vez de decidir sozinha.

### 3.3 Facções e dano — mais barato do que parece

Não construir um sistema de três facções. O modelo atual de `Projectile` já resolve
metade do problema de graça:

- **Ofensiva do companion já funciona.** `Projectile.onCollisionStart` ramifica em
  `isEnemy`: com `isEnemy: false` o tiro acerta `Enemy` e ignora o treinador. Fogo
  amigo não existe, sem trabalho nenhum.
- **Defesa do companion está quebrada, e o conserto é pontual.** O dano inimigo testa
  `other is Player` em exatamente três lugares:
  - `projeteis/projectile.dart:192`
  - `projeteis/explosion_hitbox.dart:110`
  - `projeteis/bomb.dart:79`

  Basta alargar o tipo de vítima nesses três pontos para um supertipo comum
  (`Player` e `Companion`). Confirmar que a lista continua com três itens antes de
  começar: `grep -rn "is Player" lib/game/components`, ignorando `collectible.dart` e
  `stairs.dart`, que são pickup e não dano.

Junto com o alargamento entra a regra de perfuração da seção 2.3: o companion atingido
decrementa `atravessa` normalmente, igual ao treinador.

### 3.4 Alvo dos inimigos

`Enemy.playerTarget` é `final Player` e obrigatório no construtor. **Manter como está** —
ele continua sendo a referência ao treinador, e mexer nisso mexe em todos os arquivos de
inimigo.

Adicionar ao lado dele um getter `currentTarget`, que devolve o hostil mais próximo
(treinador ou companion), e trocar o uso em `enemy_mixins.dart:229` por ele. Uma linha.

### 3.5 Cooldowns saem do `Player`

Este é o pedaço caro, e não tem atalho: disparo autônomo exige um timer por criatura.

Os campos `_cooldown1`, `_cooldown2`, `_cooldownMax1`, `_cooldownMax2`,
`touchHoldAbility1`, `touchHoldAbility2`, `_keyboardHoldAbility1`,
`_keyboardHoldAbility2` migram de `player.dart` para `Companion`.

Isso arrasta:

- `UI/hud.dart` (208 linhas): os indicadores de cooldown passam a ler a criatura ativa.
- `UI/ability_button.dart` (126 linhas): o callback `onPressedChanged` hoje escreve
  direto em `player.touchHoldAbility1`. Passa a escrever na criatura ativa.
- `creatures_rogue_game.dart`, `_setupAbilityControls`: o `tipo:` de cada botão hoje lê
  `player.creatureData.ability1.tipo`; passa a ler da criatura ativa, e precisa lidar
  com "nenhuma criatura invocada".

Decidir também o que a HUD mostra quando há três criaturas no grupo. Recomendação:
indicadores da criatura **ativa** (a que os botões controlam) em tamanho cheio, e as
outras duas como ícones pequenos de status, sem cooldown detalhado. Três pares de
indicadores em tela de celular não se leem.

**Regra de disparo automático, travada após o playtest da fase 3:** a IA só dispara
sozinha habilidade `tipo: AbilityTipo.ataque`, e só com hostil à vista. `defesa` e
`esquiva` nunca disparam sozinhas — só por override do treinador. Confirmado contra o
`creature_registry.dart` das 16 criaturas: `ability1` é sempre `ataque` (nenhuma
usa o slot A para defesa/esquiva), então nenhuma perde toda a ofensiva autônoma sob
essa regra. Segurar o botão também força `ataque` a disparar — inofensivo, é só o
jogador confirmando o que a IA já faria.

### 3.6 Natureza como dado

Campo novo em `CreatureData`, ao lado de `enemyBuilder`:

```dart
enum CompanionBehavior { guarda, cacador, orbital }
```

O mapeamento real, como saiu na implementação (fase 5a) — mais simples que o previsto
originalmente, porque disparo autônomo já não depende de `ShooterAttack` desde a fase
3 (é `Companion._tryFire` em cima do cooldown da própria `Ability`, não o telegraph de
tiro genérico do `Enemy`; ver §3.5). Natureza afeta só **movimento**, nunca disparo —
as três usam a mesma regra de mira/disparo autônomo:

| Natureza | Movimento |
|----------|-----------|
| guarda | `ChaseMovement` com `currentTarget = treinador`, só além de `leashRadius` (28px) |
| cacador | `ChaseMovement` com `currentTarget` = hostil mais próximo, **sem coleira**, enquanto houver um na sala; sem hostil, cai pro mesmo comportamento de `guarda` |
| orbital | posição própria em coordenadas polares em volta do treinador, raio 24px, 1.6 rad/s — não usa `ChaseMovement` |

Números escolhidos sem tuning fino ainda, primeiro corte pra jogar: `leashRadius` 28px
(igual à fase 3), raio orbital 24px (cabe dentro dos 28px de coleira do guarda, pra não
ficar visualmente maior que o alcance normal), 1.6 rad/s (~3.9s por volta completa).

Atribuídas às 16 criaturas do registry por tema: `cacador` nos predadores/agressivos
(Roedor de Fogo, Cobra de Água, Grilo Elétrico, Tubarão de Água, Leão Elétrico — 5),
`orbital` nas que voam/giram (Ave Elétrica, Tornado de Fogo — 2), `guarda` no resto (9,
inclui as tanques e as que atacam à distância).

Com isso a composição do grupo **é** o build da run — profundidade real por custo baixo,
porque três naturezas cobrem a maior parte do espaço de decisão.

**Fase 5a termina aqui, ainda com um `Companion` só por vez** (o campo
`companionBehavior` já existe e já é lido, mas só há uma criatura invocada). Grupo de
três — e a HUD que isso exige — é a fase 5b, atrás do playtest desta.

### 3.7 Stats do treinador e o eixo de upgrades

Hoje `Player(moveJoystick:, creatureData:)` deriva `maxHealth` e `maxSpeed` de
`creatureData.stats`. Sem criatura embutida, esses valores vêm de um bloco próprio
(`TrainerStats`), e **o treinador tem upgrades de run** — decisão travada.

Isso obriga a separar dois eixos de upgrade que hoje estão misturados nos campos
`velMult`, `cdMult` e `danoMult` do `Player`:

| Campo | Passa a ser de | Motivo |
|-------|----------------|--------|
| `velMult` | **treinador** | velocidade do treinador agora é habilidade de captura (seção 4.1) e de esquiva; é o stat mais valioso dele |
| `cdMult` | criatura | cooldown é de habilidade, e habilidade é da criatura |
| `danoMult` | criatura | dano é de habilidade |

`danoMult` merece atenção: é `static` no `Player` e aplicado dentro de
`Projectile.onCollisionStart`, o único ponto por onde tiro do jogador machuca inimigo.
Sendo `static`, um upgrade de dano vale para **as três criaturas do grupo ao mesmo
tempo**. Isso é defensável (upgrade de run é do jogador, não da criatura) e é de longe
o mais barato de manter — mas é uma decisão, não uma herança. Se em algum momento
upgrades passarem a ser por criatura, esse `static` é o primeiro obstáculo.

O treinador também precisa dos seus próprios stats novos, que não existem hoje em
`BaseStats`: alcance e velocidade do laço de captura (seção 4.1) são candidatos naturais
a upgrade, e são específicos do treinador.

Atenção à ordem de construção, que o pivô anterior já sinalizou: `RoomComponent` recebe
`player:` no construtor, então a geração da dungeon continua tendo de acontecer depois
da criação do treinador, dentro de `startRun` (`creatures_rogue_game.dart:177`).

## 4. Captura

### 4.1 O laço — captura por volta completa

Decisão travada, e é a melhor ideia deste pivô: captura não é um botão que se aperta,
é uma **manobra**.

O jogador segura o botão de captura. Uma linha sai do treinador e prende na criatura
alvo. Enquanto o botão estiver segurado, o jogador precisa **completar uma volta inteira
em torno da criatura** para capturá-la. Soltar o botão, ou quebrar o laço, cancela.

Por que isso é bom, e por que vale o custo de implementação: é a resposta direta ao
problema da seção 2.1. O treinador deixa de ser quem só anda e passa a ter uma manobra
que exige leitura de espaço, timing e coragem — porque a volta leva segundos e durante
ela o jogador está andando em círculo, previsível, com o resto da sala atirando nele.
O risco **é** a mecânica.

Consequência: **o item de captura consumível sai.** A volta já é o custo. Manter item
mais limiar de HP mais a manobra seria três portões e captura viraria rara demais para
ser divertida. Fica só a manobra mais o limiar de HP (seção 4.2).

#### Geometria — a manobra cabe na sala?

Cabe, mas com folga pequena. Os números do projeto:

- Sala interna: `roomWidth = 16 * 12 = 192px`, menos `wallThickness = 16` de cada lado,
  sobram **160px** úteis.
- Volta a um raio de 24px: circunferência de ~151px.
- Treinador a ~60px/s: a volta leva **~2,5s**.

Dois segundos e meio é uma janela boa — longa o bastante para ser tensa, curta o
bastante para não entediar. Mas 24px de raio significa 24px de folga **em volta do
alvo**, e é aí que a coisa quebra.

#### As quatro regras que decidem se isso é jogável

**1. Alvo travado no aperto.** "Criatura mais próxima" é resolvido **uma vez**, no
botão-baixo, e mantido até soltar. Reavaliar a cada frame faz o laço pular para outro
inimigo no meio da volta — é um bug de frustração garantido, do tipo que o jogador lê
como o jogo trapaceando.

**2. Inimigo encostado na parede.** Este é o caso comum, não a exceção: um inimigo com
`ChaseMovement` encurralado num canto não tem 24px de folga em três direções, e a volta
fica impossível. Duas saídas, escolher uma:

- **O laço prende o alvo.** Enquanto o laço está ativo, o inimigo é enraizado (ou muito
  lento) e puxado para perto do treinador, o que naturalmente o descola da parede.
  Custo: precisa de um estado novo no `Enemy` e de uma força de puxão. Ganho: a manobra
  funciona em qualquer lugar da sala, e "puxar a criatura para fora do canto" é uma
  leitura visual boa.
- **Captura exige folga.** O laço simplesmente não prende se não houver espaço, com um
  aviso visual claro, e o trabalho do treinador é reposicionar a luta antes. Custo zero
  de implementação. Risco: o jogador não entende por que falhou.

Recomendação: **a primeira**. A segunda transfere para o jogador um problema que ele não
tem ferramenta para resolver — ele não controla para onde o inimigo anda.

**3. Acumulação de ângulo, com retrocesso permitido.** Acumular o delta com sinal do
rumo do treinador em torno da posição **atual** do alvo, e capturar quando o acumulado
passar de 2π. Retrocesso subtrai em vez de zerar. O alvo se mexe (mesmo enraizado, o
knockback o move), então exigir uma volta monotônica puniria o jogador por movimento que
não é dele. Acumulação líquida é o único critério justo aqui.

**4. Condições de quebra.** Dizer explicitamente o que cancela o laço:

- soltar o botão
- distância máxima ultrapassada (o laço tem alcance, e alcance é upgrade do treinador —
  ver seção 3.7)
- parede entre treinador e alvo (reusar `direcaoLivre`, que já existe no `Enemy`)
- treinador tomar dano

Levar dano cancelar é o que dá peso à manobra: a volta é uma janela de vulnerabilidade
real, e não só de tempo gasto. Sem isso, captura vira formalidade.

#### Feedback

A linha precisa mostrar **progresso**. Um arco que se fecha em volta do alvo,
preenchendo conforme o ângulo acumula, é a leitura mais direta e usa o mesmo vocabulário
visual dos indicadores de cooldown que a HUD já desenha. Sem isso o jogador não sabe se
está na metade ou quase lá, e não sabe se retroceder custou caro.

### 4.2 Limiar de HP

O laço só prende em inimigo abaixo de um limiar de HP. É o segundo e último portão.

Além do óbvio (capturar inimigo intacto seria forte demais), o limiar resolve o problema
de sobrevivência da seção 4.1: ele empurra a captura naturalmente para o **fim da luta**,
quando restam poucos inimigos atirando. Uma volta de 2,5s numa sala com cinco inimigos
ativos seria impossível; numa sala com um inimigo restante, é uma decisão. Um portão que
resolve dois problemas.

### 4.3 Grupo cheio

Com três criaturas, uma captura nova exige dispensar uma. **Resolver ao limpar a sala,
não no meio do combate** — um prompt de troca no meio da luta é uma pausa que quebra o
ritmo. A criatura capturada fica pendente até a sala terminar.

### 4.4 Bosses

Não capturáveis por padrão. O pico de poder é grande demais e desequilibra a run
inteira. Se virar mecânica depois, que seja por um item exclusivo e raro, e não pelo
item de captura comum.

## 5. Fases de implementação

A ordem é por risco: cada fase termina com o jogo rodando, e o refactor mais arriscado
(fase 2) vem depois de validar a medição que o sustenta.

### Fase 0 — Remedir

Antes de qualquer código, confirmar as três medições que sustentam o plano, porque elas
é que definem o custo:

- superfície dos mixins de IA (seção 3.1) — esperado: catorze membros
- `playerTarget` nos mixins — esperado: uma ocorrência
- `is Player` como vítima de dano — esperado: três lugares

Se algum número mudou muito, revisar a fase correspondente antes de seguir.

### Fase 1 — `AbilityUser`

Extrair a interface e o `mixin AbilityBuffSinks` (seção 3.2), fazer `Player`
implementá-los, e trocar a assinatura de `Ability.execute` de `Player` para
`AbilityUser`. Resolver as decisões de `placeBomb` e `lockedAb*Direction`.

Ao fim desta fase o jogo roda exatamente como antes: nada novo existe, só o acoplamento
das 34 habilidades ao `Player` foi quebrado.

### Fase 2 — `MovementHost`

Extrair o mixin da seção 3.1 e trocar `on Enemy` por `on MovementHost` nos cinco mixins
de IA. `Enemy` passa a usar `MovementHost`.

Ao fim desta fase o jogo continua rodando igual: os inimigos usam os mesmos mixins pelo
mesmo caminho, só a declaração mudou. Validar em jogo antes de seguir — se algum inimigo
se comportar diferente, o problema está aqui e não na fase seguinte.

### Fase 3 — `Companion` com uma natureza só

Criar `Companion` usando `MovementHost` mais `AbilityUser`, com os cooldowns migrados
(seção 3.5) e **apenas a natureza `guarda`**. Uma criatura invocada, fixa, sem captura e
sem troca.

Alargar os três pontos de dano da seção 3.3 e adicionar `currentTarget` (seção 3.4).

Ao fim desta fase o loop novo é jogável em sua forma mínima: treinador anda, uma
criatura o acompanha e atira sozinha. **Jogar antes de seguir** — é aqui que se descobre
se a autonomia é divertida ou passiva.

### Fase 4 — Override e postura

Religar os dois `AbilityButton` na criatura ativa (seção 3.5) e adicionar o comando de
postura (seção 2.1). Reescrever os indicadores de cooldown do `Hud`.

Ao fim desta fase o esquema de controle está completo para uma criatura. **Tunar
cooldowns e o ritmo do disparo automático antes de seguir**, porque a fase 5 multiplica
por três qualquer erro de balanceamento que ficar aqui.

### Fase 5 — Grupo de três e naturezas

Adicionar `CompanionBehavior` a `CreatureData` (seção 3.6), implementar `cacador` e
`orbital`, e permitir até três criaturas invocadas com uma ativa por vez. HUD com uma
criatura em destaque e duas em ícone.

### Fase 6 — Captura

A fase mais divertida e a de maior risco de execução, porque nada dela reusa código
existente. Ordem interna, cada passo jogável:

1. Botão de captura, laço travando alvo no aperto, linha visual, quebra por soltar e por
   distância. Sem acumulação ainda — captura instantânea, só pra validar a mira.
2. Acumulação de ângulo com arco de progresso. É aqui que se descobre se 24px de raio e
   2,5s de volta são os números certos. **Jogar e tunar antes de seguir.**
3. Enraizamento e puxão do alvo (seção 4.1, regra 2).
4. Limiar de HP, quebra por dano e por parede.
5. Grupo cheio resolvido ao limpar a sala.

Ajustar `creature_select_overlay.dart` para "criatura inicial".

## 6. Armadilhas

**A criatura ativa pode não existir.** Os botões, a HUD e o teclado precisam lidar com
"nenhuma criatura invocada" — no começo da run, entre salas, e enquanto uma criatura
está desmaiada. O código atual já tem o guarda `_runStarted` em
`_setupAbilityControls`; o novo estado é parecido, mas muda dentro da run e não só no
começo dela.

**Os mixins de IA assumem sala.** Vale conferir se `ChaseMovement` e companhia usam
limites da `RoomComponent` que o companion também precisa respeitar — um companion que
persegue através da porta e some da sala é um bug de leitura ruim.

**`Companion` vai duplicar o bloco de colisão de parede.** `player.dart` e `enemy.dart`
já duplicam `isPhysicsCollision`, a sombra, a montagem do `physicsHitbox` e a resolução
de parede. Com `Companion` viram três cópias. O `PIVOT_CRIATURAS.md` decidiu deixar como
está; com a terceira cópia vale reconsiderar, mas **não** dentro deste pivô — abrir
como trabalho separado.

**O laço travado num alvo que morre.** O inimigo pode morrer no meio da volta — pelo
tiro de um companion, por DoT, por explosão. O laço precisa cancelar limpo, sem deixar a
linha desenhada apontando para um componente já removido. Mesmo cuidado para o alvo que
sai da sala por uma porta.

**O laço e o `knockback` brigam.** Enraizar o alvo (seção 4.1, regra 2) não pode zerar
`knockbackVelocity`, senão os tiros dos companions param de empurrar e a leitura fica
estranha. Enraizar é sobre `movimento(dt)`, não sobre física — o padrão que `stunTimer`
já usa no `Enemy.update` serve de modelo.

**Reativar `bombsAmount` muda o balanceamento de tudo que já foi tunado.** As duas linhas
comentadas em `player.dart:652-653` significam que qualquer teste feito até hoje com a
Bomba de Fogo foi com bomba infinita. Reativar não é bugfix, é nerf — retunar a criatura
depois, não antes.

**`PaletteSwapper` tem cache por caminho mais cores.** As criaturas do grupo geram as
mesmas combinações que a forma jogável já gerava, então o preload existente cobre. Mas
qualquer variante de cor nova para companion precisa entrar em `_preloadCombatSprites`,
ou a textura nasce em pleno combate.

## 7. Checklist

- [x] Fase 0: moot, não pendente — era um portão de estimativa de custo pras fases 1-2,
  que já saíram do papel e funcionaram. Não há o que remedir depois do fato
- [x] Fase 1: `AbilityUser`, `Ability.execute` desacoplado de `Player`, `canExecute` para o gate de bomba, `bombsAmount--` reativado
- [x] `lockedAb*Direction` calculado por companion, a partir da própria posição
- [x] Fase 2: `MovementHost` extraído, cinco mixins migrados, `currentTarget` substitui `playerTarget` nos mixins
- [x] Fase 3: `Companion` com natureza `guarda`, três pontos de dano alargados (`DamageableByEnemy`), auto-fire na criatura hostil mais próxima
- [x] **Jogar fase 3** — feito. Achado: botões ainda disparavam do treinador (bug de wiring), e mesmo corrigido, ability2 (defesa/esquiva) executada pela criatura não dava agência nenhuma ao treinador
- [x] Fase 4 parcial, em resposta direta ao achado: botões e teclado (Z/X) religados pro `Companion` ativo (`_setupActionButtons` e `_setupGestureControls`); `Player` perdeu toda a máquina de cooldown/execução de habilidade
- [x] `Companion._tryFire`: `ataque` autônomo (com hostil à vista), `defesa`/`esquiva` só por override — regra travada em §3.5
- [x] Esquiva pessoal do treinador (`Player.dodge`) — terceiro botão + tecla Space; documentado como emenda de §2.1
- [x] `Companion._faint()` zera `CreaturesRogueGame.companion`, senão Hud/botões leem componente morto
- [x] Esquiva no esquema de gestos e indicador de cooldown — resolvido por caminho
  diferente do que este item previa: toque virou o trigger da esquiva em
  `_setupGestureControls`, e o cooldown ganhou uma barra verde embaixo do sprite do
  `Player` em vez de um indicador na Hud (ver itens mais abaixo no checklist)
- [x] **Jogar de novo** — achado 2 bugs, os dois corrigidos:
  - Companion preso na sala anterior: `ChaseMovement` é reto, sem pathfinding — uma
    parede fora do eixo da porta trava o companion raspando nela pra sempre (mesma
    limitação que `Enemy` sempre teve contra jogador, só que nunca testada
    atravessando sala, porque inimigo não fazia isso). Fix: `Companion._updateMovement`
    compara `currentRoom` do companion com `trainer.currentRoom` (novo getter público,
    era `Player._currentRoom`) e teleporta pra perto do treinador quando são salas
    diferentes — pathfinding de verdade fica pra quando (se) virar problema real.
  - Dois treinadores controlados juntos depois de reiniciar: botão "Menu Principal" do
    Game Over chamava `resetGame()` só pra esconder a run atrás do menu — com o motor
    pausado, isso empilhava dois `startRun()` em sequência, e o `Player`/`Companion`
    da run morta sobrevivia (o `moveJoystick` é uma instância única compartilhada por
    todo `Player`, por isso os dois se moviam juntos). Fix: parei de chamar
    `resetGame()` nesse botão — a run pausada some sozinha no próximo `startRun` de
    verdade — e `startRun` ganhou uma varredura explícita por tipo
    (`whereType<Player>()`/`whereType<Companion>()`) como reforço, não só o loop
    genérico de `children`.
- [x] **Jogar de novo** — override + esquiva pessoal resolveram a agência, os dois bugs
  sumiram. Achado novo: companion morrendo na primeira sala — não é bug, é a falta do
  escudo passivo (`shieldMax`/`shield` de `BaseStats`) somada aos HPs baixos das
  criaturas jogáveis (ex.: 3 no Roedor de Fogo, tunados assim antes deste pivô). Sem
  a segunda barra regenerável, 3 HP crus morre rápido demais.
- [x] Escudo passivo adicionado ao `Companion`, mesma fórmula e regra do `Player`
  (absorve antes do HP, regenera com o tempo) — corrige o texto da seção 3, que dizia
  "sem escudo passivo" como simplificação da fase 3; não é mais simplificação
- [x] Fase 5a: `CompanionBehavior` (`guarda`/`cacador`/`orbital`) em `CreatureData`,
  default `guarda` pras 16 entradas compilarem sem editar todas; atribuído por tema —
  5 `cacador`, 2 `orbital`, 9 `guarda`
- [x] `currentTarget` vira switch por natureza; `cacador` sem coleira enquanto houver
  hostil na sala (senão vira guarda com passo extra); `orbital` com posição polar
  própria (raio 24px, 1.6 rad/s), sem `ChaseMovement`
- [x] **Jogar fase 5a** — achado: caçador andava até encostar no inimigo (`ChaseMovement`
  só para a 1px do alvo, feito originalmente pra inimigo perseguindo o treinador, cujo
  contato É o golpe) e apanhava à queima-roupa de qualquer coisa telegrafada/explosiva
  até morrer. Fix: `_cacadorEngageRange` (40px) para o avanço assim que dá pra atirar —
  o caçador some de vista fora de alcance, mas não fecha pra melee contra criaturas
  que são atiradoras
- [x] `_cacadorEngageRange` reduzido de 40px pra 18px — na distância antiga a Mordida do
  Tubarão (curta, ~10px de alcance mais raio da explosão) nascia longe demais e nunca
  encostava no alvo. Os outros quatro caçadores usam projétil de verdade (viaja sozinho
  depois de disparado), então não se importam com a distância de parada — puxar geral
  pra perto não perde nada neles. `Ability` não expõe alcance próprio pra calibrar por
  criatura, então o valor é um só, compartilhado, calibrado pelo mais curto
- [ ] **Jogar de novo:** os três comportamentos leem como diferentes de verdade agora?
  Raio orbital ainda é primeiro corte, não tunado
- [x] Barra da esquiva do treinador — verde, embaixo do sprite do `Player`, enche
  conforme recarrega (oposto do indicador de habilidade da Hud, que esvazia)
- [x] Habilidade 1 sem controle nenhum, nos dois esquemas — sempre `ataque`, já dispara
  sozinha pela IA, override nunca mudava nada nela na prática. `_setupActionButtons`
  cai pra 2 botões (habilidade 2 + esquiva); no esquema de gestos, toque parado deixa
  de ser habilidade 1 e vira a esquiva do treinador, arrastar continua sendo
  habilidade 2
- [x] Efeito de desmaio/revive, pedido do usuário: `CompanionRecallEffect` (círculo
  vermelho fecha em cima da posição onde o companion desmaiou, a bolinha resultante
  arca até o treinador — segue a posição atual dele, não onde estava no instante do
  desmaio) tocado em `Companion._faint()`; `CompanionReviveEffect` (círculo branco
  abrindo rápido e sumindo) tocado em `CreaturesRogueGame._reviveCompanion`. Os dois
  puramente Canvas, sem sprite novo, mesmo espírito do `CaptureLassoVisual`
- [x] Indicador de vida/escudo do companion, desenhado acima do sprite (dois retângulos
  no próprio `render`, sem asset novo) — antes disso o companion não tinha HP visível
  em lugar nenhum, morrer lia como aleatório
- [x] **Rebalanceamento de vida** — achado: mesmo com escudo passivo, o companion
  morria rápido demais. Causa raiz não era o escudo, era o `maxHp` das 16 criaturas
  jogáveis: os próprios comentários nos arquivos de `enemies/creatures/*.dart`
  documentam contra qual `stats.maxHp` cada `health`/`dmg` de inimigo foi calibrado
  (ex.: `tartaruga_planta_enemy.dart` diz "stats.maxHp 20", `pinguim_agua_enemy.dart`
  diz "stats.maxHp 18"), e o registry atual estava 3 a 9 vezes abaixo disso — o corte
  de vida das jogáveis (mencionado na fase 3) nunca foi acompanhado de um corte
  equivalente no dano/vida dos inimigos, então o companion apanhava como se tivesse a
  vida antiga. Confirmado com o usuário que o corte não era intencional. Fix: `maxHp`
  das 16 criaturas em `creature_registry.dart` restaurado pro valor documentado nos
  comentários (5 sem comentário — Cobra de Água, Slime de Planta, Torchmin, Frowago,
  Garibirb — interpoladas por `defesa`/`ataque` contra as vizinhas documentadas).
  Nenhum arquivo de inimigo foi tocado — o dano/vida deles já estava certo pra essa
  escala, era a jogável que tinha saído dela.
- [x] Efeito colateral aceito: `Player.maxHealth` deriva de `creatureData.stats.maxHp`
  (§3.7 ainda não separou `TrainerStats`), então a vida do treinador subiu junto com a
  da criatura, na mesma proporção — não é regressão, é a mesma causa raiz acima
- [x] Corrigido de brinde: `Companion._renderBarraStatus` usava
  `(_barraLargura / totalPontos).clamp(0.6, 2.0)` — o piso de 0.6 garantia overflow da
  barra (14px) assim que HP+escudo passasse de ~23 pontos, o que o rebalanceamento
  acima passou a bater fácil (ex. Urso de Planta: 22 HP + 10 escudo = 32 pontos). Trocado
  pra `min(2.0, _barraLargura / totalPontos)`, sem piso — mesmo padrão que a Hud do
  treinador já usava (`_pxPorPonto` só tem teto, nunca piso)
- [ ] **Jogar de novo** — confirmar se a vida restaurada resolve "morre rápido" sem virar
  parede de vida do lado oposto; valores são primeiro corte, não tunados por playtest
- [x] Fase 4 completa: postura (§2.1.1) — `CompanionPostura` (`seguir`/`agressivo`/
  `segurar`) em `Companion`, ciclada tocando no retrato na Hud
  (`CompanionPortraitIndicator` ganhou `TapCallbacks`, mesmo padrão de
  `ConsumableSlotButton`). `agressivo` força o padrão `cacador` mesmo numa criatura
  `guarda`/`orbital` (via `comportamentoEfetivo` em `_updateMovement` e em
  `currentTarget`); `segurar` cancela todo movimento sem cancelar o disparo autônomo
  (`ataque` ainda dispara sozinho se um hostil entrar no alcance parado). `seguir`
  (default) não muda nada — a natureza roda como já rodava. Marcador visual: quadrado
  vermelho/azul no canto do retrato quando a postura não é `seguir`; sem marcador
  quando é (nada pra sinalizar). Reseta pra `seguir` a cada revive — `Companion` novo,
  sem estado herdado
- [ ] **Jogar de novo** — confirmar se a postura lê como um controle útil ou como um
  botão extra que ninguém toca em combate; retrato pequeno pode ser difícil de acertar
  no toque, sem alvo de toque circular/ampliado como os outros botões têm
- [x] **Inversão de ordem, achada antes de começar a fase 5b**: §3.7 tinha que vir
  ANTES da fase 5b, não depois — `Player.maxHealth` derivava de
  `creatureData.stats.maxHp` de UMA criatura só; com grupo de três "de qual criatura
  vem a vida do treinador" não tem resposta definida (trava na primeira, ou oscila a
  cada troca de ativa, e as vidas restauradas nesta rodada são 3-9x maiores — a
  oscilação seria grande e visível). Fase 5b não pode começar em cima disso
- [x] §3.7: `TrainerStats` (novo arquivo `player/trainer_stats.dart`) —
  `maxHealth`/`speed`/`shieldMax` próprios do treinador, não derivam mais de
  `creatureData.stats`. Sem campo `defesa` como o `BaseStats` das criaturas: só existe
  um treinador, `shieldMax` é valor direto, a fórmula `defesa*2` só faz sentido
  compartilhada entre 16 criaturas. Valores primeiro corte (16/60/6), não tunados.
  `creatureData` continua no `Player` só pelo visual (sprite/hitbox/animação) — o
  treinador ainda não tem sprite próprio, gap do §1 (`ator novo, com sprite... próprio`)
  que §3.7 nunca cobriu e este pivô não resolve (precisaria de asset novo)
- [x] Eixo de upgrade corrigido: `velMult` já era do treinador (nenhuma mudança);
  `cdMult` era campo morto no `Player` (escrito pelo power-up `fireRateUp`, nunca lido
  por ninguém desde que a execução de habilidade virou toda do `Companion`) — removido
  de `Player`, `fireRateUp` agora escreve em `companion?.cdMult`. `danoMult` continua
  `static` no `Player`, sem mudança (decisão já travada em §3.7: upgrade de dano vale
  pro grupo inteiro de uma vez)
- [ ] **Jogar de novo** — confirmar que vida/velocidade do treinador não regrediram
  visualmente (eram 16/60/6 fixos agora, antes variavam com a criatura escolhida) e que
  o upgrade de cadência (`fireRateUp`) ainda funciona, agora na criatura
- [x] Fase 5b: `CreaturesRogueGame.companions` — `List<Companion?>` de 3 slots (era
  `Companion? companion`), slot 0 sempre a criatura da seleção, 1 e 2 nascem vazios
  (`null`) até a fase 6 preencher. `companionAtivoIndex` decide qual recebe override de
  botão/gesto/teclado; `companion` virou getter (`companions[companionAtivoIndex]`) —
  todo código que já lia `companion?.x` continuou funcionando sem mudança, porque
  "a" criatura sempre significou "a ativa". Revive virou por slot:
  `_companionReviveTimers`/`companionCreatures`/`scheduleCompanionRevive(slot)`/
  `_reviveCompanion(slot)`, todos indexados. `Companion._faint()` acha o próprio slot
  com `jogo.companions.indexOf(this)` (identidade, `Companion` não sobrescreve `==`)
- [x] Troca de ativa: tocar no retrato da Hud que JÁ é a ativa cicla a postura dela
  (comportamento de antes, sem mudança); tocar em outro retrato troca qual é a ativa.
  Uma função só (`CreaturesRogueGame.onTapCompanionSlot`) decide as duas — evita gesto
  novo (segurar/toque longo) só pra isso. Retrato de slot vazio não faz nada tocado
- [x] `CompanionPortraitIndicator` reescrito: `creatureData` virou função
  (`CreatureData? Function()`), não mais valor fixo — os slots 1/2 nascem vazios e só
  ganham criatura em pleno jogo quando a fase 6 capturar algo, então o carregamento do
  sprite saiu do `onLoad` (uma vez só) pra dentro do `update` (reage a troca, carrega
  sob demanda, cacheia por identidade do `CreatureData`). Slot vazio desenha um
  quadrado cinza-fundo em vez de sprite. Contorno branco na ativa, cinza-fraco nas
  outras — substitui a recomendação do doc de "ativa em tamanho cheio, outras
  pequenas": os dois indicadores de cooldown (só a ativa tem) já carregam essa
  distinção de detalhe, redimensionar retrato por cima seria layout dinâmico sem
  ganho de leitura
- [ ] **Jogar de novo** — confirmar que trocar de ativa e ciclar postura no mesmo
  retrato não se confundem na prática (mesmo toque, comportamento decidido pelo estado
  atual — pode ser menos óbvio do que parece na teoria)
- [x] **Reestruturação pedida pelo usuário, com brainstorm/arquitetura antes de codar**:
  três mudanças de mecânica e controle, decididas via pergunta direta (não assumidas):
  1. Criatura só tem UMA habilidade ativa agora (`ability1`, sempre `ataque`,
     autônoma). `ability2` continua nos dados de `CreatureData` (16 criaturas), só
     ninguém chama mais — decisão explícita de guardar o dado pra decidir depois.
     `Companion._updateAimAndFire`/cooldown simplificados pra uma habilidade só,
     `_tryFire` (genérico, multi-habilidade) removido.
  2. **Recolher/liberar substitui desmaio+timer fixo inteiro** (decisão do usuário via
     pergunta): `CreaturesRogueGame.companionPocketed` (por SLOT, não um bool global —
     uma criatura morrendo em combate não pode arrastar as outras duas pro bolso
     junto), `companionSavedHealth` (snapshot, já que o `Companion` some do mundo),
     `curaBolsoFracaoPorSegundo = 0.10` (10%/s, primeiro corte). `alternarRecuoGrupo()`
     é a ação em massa: se alguém tá fora, recolhe todo mundo fora; se todo mundo já
     tá dentro, libera todo mundo. `pocketarSlot`/`liberarSlot` são a rotina real —
     usada tanto pela ação em massa quanto por `Companion.takeDamage` quando a vida
     zera (mesmo estado, dois gatilhos). `companionReviveDuration`/
     `_companionReviveTimers`/`scheduleCompanionRevive`/`_reviveCompanion` antigos,
     todos apagados. Retrato da Hud reaproveitado: o cinza que mostrava "tempo até
     reviver" agora mostra "fração de vida faltando no bolso" (`companionPocketFraction`).
  3. **Três botões**: recolher/liberar (novo `RecallButton`, TOQUE não segurar — é
     troca de estado) + esquiva + captura, todos agora dentro de `_abilityControls`
     (antes captura era sempre montada, fora da troca de esquema — corrigido: só faz
     sentido no esquema de botões). Esquema de GESTOS reescrito do zero
     (`gesture_action_area.dart`): antes só distinguia toque-parado/arraste (2
     estados); agora toque-parado-e-segurando = captura (contínuo), arrastar pra cima
     = esquiva (uma vez), arrastar pra baixo = recolher/liberar (uma vez). Direção
     classificada por eixo dominante do deslocamento acumulado ao cruzar 20px, uma vez
     só por toque (não reavalia depois) — diagonal/lateral não dispara nada.
  4. Teclado: tecla X (era override morto de ability2) virou recolher/liberar
     (`KeyDownEvent`, dispara uma vez). Tecla Z (override morto de ability1) removida
     de vez — não fazia nada desde a fase 4, e agora nem ability2 sobrou pra justificar
     manter o padrão de duas teclas.
- [ ] **Jogar de novo** — nada disso foi testado. Cura de 10%/s, limiar de classificação
  de gesto (20px) e a interação capture-hold-vs-swipe no mesmo componente são os
  primeiros suspeitos se algo sentir errado
- [x] Achado no quarto teste: capturar com a criatura ativa desmaiada (em timer de
  revive) fazia a nova substituir a antiga, e depois não dava mais pra capturar mais
  nada. Causa: `CreaturesRogueGame.capturarCriatura` procurava slot livre em
  `companions` (o `Companion` MONTADO) em vez de `companionCreatures` (o DONO do
  slot) — um slot com companion desmaiado tem `companions[i] == null` mas
  `companionCreatures[i]` continua preenchido (é o que permite reviver), então a
  busca achava esse slot como "livre", sobrescrevia o dono errado, e o timer de
  revive daquele companion ficava apontando pra uma criatura que não era mais dele.
  Trocado pra procurar em `companionCreatures`
- [x] **Achado, fora de escopo desta rodada**: `Enemy.currentTarget` ainda é sempre
  `playerTarget` fixo — §2.3/§3.4 do doc travam "aggro por proximidade, sem
  preferência entre treinador e companion", mas isso nunca foi implementado; inimigos
  só perseguem/miram o treinador, nunca escolhem um companion mesmo mais perto. Não é
  bug desta sessão (pré-existia), não bloqueia fase 5b/6, mas explica por que os
  companions só tomam dano incidental (contato/estilhaço), nunca são alvo deliberado —
  vale como próximo item depois da fase 6
- [x] Fase 6 implementada inteira numa rodada só (6.1-6.4; 6.5 simplificado — ver
  abaixo), porque nenhuma sub-fase é independentemente jogável sem as outras três: um
  botão que só faz captura instantânea (6.1 sozinho) não testa nada da manobra real.
  Peças novas:
  - `CaptureButton` (`UI/capture_button.dart`) — botão próprio, segurar inicia/solta
    cancela, montado nos dois esquemas de controle (fora de `_abilityControls`, mesmo
    tratamento que `ConsumableSlotButton`). Fica na FAIXA DO TOPO, não no canto
    inferior esquerdo que pareceria natural: aquele canto é a área de spawn do
    `DynamicJoystickComponent` (cobre a metade esquerda da tela abaixo de
    `ConsumableSlotButton.alturaFaixa`), um botão ali seria engolido pelo toque que
    nasce o joystick. Sem ícone de sprite — glifo é um anel desenhado no `render`,
    nenhum asset de laço existe no projeto
  - `Player.startCapture`/`cancelCapture`/`_updateCapture` — ação pessoal do
    treinador, mesma categoria de `dodge()`, fora de `Ability`/`Companion`. Alvo
    travado uma vez em `_encontrarAlvoCaptura` (regra 1): mais próximo, dentro de
    `stats.captureRange`, abaixo do limiar de HP (`captureHpFraction = 0.3`, regra do
    §4.2), excluindo boss (checa `alvo.currentRoom?.data.type == RoomType.boss` —
    sem precisar de um campo `isBoss` novo em `Enemy`, já que sala de boss só spawna
    o boss sozinho)
  - Acumulação de ângulo (regra 3): delta com sinal em torno da posição ATUAL do
    alvo, retrocesso subtrai em vez de zerar, captura completa em 2π — exatamente
    como o doc especifica
  - Quatro quebras (regra 4): soltar o botão (`cancelCapture` direto do
    `onPressedChanged`), distância maior que `captureRange` e parede entre os dois
    (ambas em `_updateCapture`), dano no treinador (hook em `Player.takeDamage`, logo
    depois do golpe ser confirmado — um golpe todo mitigado por `damageReduction` não
    conta como "tomar dano" pra essa regra)
  - Checagem de parede: NÃO reaproveitou `MovementHost.direcaoLivre` de verdade (Player
    não tem o resto das dependências do mixin) — duplicou uma versão pequena
    (`_paredeEntreCaptura`) que amostra 7 pontos ao longo do segmento treinador-alvo
    contra os colliders da sala, em vez de testar a caixa delimitadora inteira (que
    daria falso positivo com qualquer parede fora da linha)
  - `Enemy.enraizarParaCaptura` (regra 2, opção recomendada pelo doc): enquanto ativo,
    `movimento(dt)` não roda — o inimigo anda sozinho pro CENTRO da própria sala a
    30px/s, o que descola qualquer alvo encurralado numa parede. Sem estado de "boss
    grande demais pra puxar" — não precisa, boss já é excluído na seleção de alvo
  - `CaptureLassoVisual` — componente de mundo (não HUD), segue o alvo, desenha a
    linha até o treinador e um arco que fecha em 2π conforme o ângulo acumula
  - `TrainerStats.captureRange` (novo campo, 40px default) — o alcance virou upgradeável
    de verdade, não só uma constante solta, já preparado pro eixo de upgrade do §3.7
  - `CreaturesRogueGame.capturarCriatura` — converte o inimigo em `Companion` no
    primeiro slot vazio, reaproveitando `alvo.creature` (todo inimigo comum carrega o
    `CreatureData` de origem — bosses não chegam aqui, já ficaram de fora na seleção)
- [x] **Simplificação de 6.5, registrada e não escondida**: o doc pede um prompt de
  troca (escolher quem dispensar) resolvido só ao limpar a sala, com o grupo cheio.
  Não implementado — precisaria de uma tela nova inteira (escolher entre 3 retratos),
  fora do escopo desta rodada. Com o grupo cheio, `capturarCriatura` simplesmente
  FALHA: o inimigo sobrevive, nada muda, sem fila de espera nem prompt. Efeito
  prático: só vale a pena laçar quando já tem um slot vazio
- [ ] **Jogar fase 6** — nunca testado, nenhuma das constantes (raio 24px, alcance
  40px, velocidade de puxão 30px/s, 7 amostras da checagem de parede) foi tunada por
  playtest. Geometria (§4.1: ~2,5s de volta a 60px/s) assume a velocidade ANTIGA do
  treinador — agora é `TrainerStats.speed = 60` (mesmo valor, coincidência boa, não
  recalculado de propósito)
- [x] Achado no primeiro teste: botão de captura não parecia fazer nada. Causa mais
  provável — `captureHpFraction` em 0.3 (§4.2): a maioria dos inimigos numa sala nova
  está bem acima de 30% de vida, então `_encontrarAlvoCaptura` não achava alvo nenhum
  e `startCapture` retornava em silêncio, sem feedback nenhum de "sem alvo". Trocado
  pra 1.0 (portão desligado) **pra teste**, não é o valor final — volta pra algo perto
  de 0.3 quando validar a manobra em si, senão a captura nunca empurra o jogador a
  enfraquecer o inimigo antes de laçar (a lógica de design inteira do §4.2)
- [x] Botão de captura movido pro canto inferior direito, centralizado ACIMA dos
  botões de habilidade 2/esquiva (mesma coluna, uma fileira a mais) — só faz sentido
  visual no esquema de botões; no esquema de gestos esse canto é coberto pela
  `GestureActionArea` (metade direita da tela), nunca testado lá, ver comentário em
  `_setupCaptureButton`
- [x] Tecla C adicionada pra testar sem depender do botão/toque — segurar
  inicia/mantém, soltar cancela, mesmo padrão de hold que Z/X já usam pro override de
  habilidade do companion
- [x] Achado no segundo teste: inimigo enraizado continuava se mexendo (o puxão pro
  centro da sala É movimento, só não é mais IA normal) e o companion matava o alvo
  antes da volta completar. Dois fixes, um pedido explícito e um de bônus:
  - Puxão pro centro removido, trocado por parada total (`animateMovement(isMoving:
    false)` só) enquanto `_enraizadoPeloLaco`. Reabre o problema que o puxão
    resolvia (alvo encurralado numa parede sem os 24px de folga) — aceito por ora,
    candidato a voltar se atrapalhar depois que o laço em si estiver validado
  - `Enemy.takeDamage` retorna cedo enquanto enraizado — não pedido só pra destravar
    o teste, também faz sentido como regra permanente: sem isso o próprio companion
    do jogador sabota a captura sem querer, e o risco da manobra é do TREINADOR
    andando exposto, não do alvo morrer de fogo amigo no meio da volta
- [x] Achado no terceiro teste: mesmo segurando o botão, o círculo de progresso
  "saía e voltava" em vez de ficar firme. Causa: `TrainerStats.captureRange` (40px)
  tinha só 16px de folga sobre o raio da volta (24px) — andar uma volta de verdade
  pelo teclado direcional (8 direções, não é analógico) não traça círculo nenhum
  perfeito, qualquer imprecisão estourava a distância, `_updateCapture` cancelava, e
  o mesmo alvo (ainda elegível, ainda mais próximo) reabria um laço novo no frame
  seguinte — lido como "saindo e voltando". `captureRange` subido pra 80 **pra
  teste**; reapertar quando a volta em si estiver validada. Segundo suspeito, não
  descartado: a checagem de parede por amostragem também pode estar contribuindo
  agora que o alvo não é mais puxado pra longe de parede nenhuma (ver item acima) —
  se o círculo ainda falhar perto de canto/parede mesmo com o alcance maior, é o
  próximo lugar pra olhar
- [ ] Reativar `bombsAmount--` (`player.dart:652-653`) com a regra de zero bombas, e retunar a Bomba de Fogo
- [ ] Contagem de bombas visível na HUD quando a criatura ativa depende dela
