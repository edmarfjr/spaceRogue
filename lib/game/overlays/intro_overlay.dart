import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
import 'package:creatures_rogue/game/overlays/selecao_widgets.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/overlays/creature_select_overlay.dart';
import 'package:creatures_rogue/l10n/ability_passive_i18n.dart';
import 'package:creatures_rogue/l10n/creature_i18n.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';

/// Abertura do jogo, vista uma vez só: apresenta o mundo em páginas de
/// diálogo e termina com a escolha da criatura inicial — a única liberada na
/// primeira run.
///
/// Não abre no boot do app: quem decide é o "NOVO JOGO" do `MainMenuOverlay`,
/// que consulta `CreatureProgress.introConcluida`. Da segunda run em diante o
/// mesmo botão vai direto pro [CreatureSelectOverlay], que já lida com
/// criaturas travadas.
///
/// As duas fases (diálogo e escolha) moram no mesmo overlay porque a
/// transição entre elas é a mesma tela, e porque o overlay precisa se remover
/// antes de chamar `startRun` — o `startRun` só remove `'CreatureSelect'`,
/// então um segundo overlay ficaria pendurado em cima da dungeon rodando.
class IntroOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const IntroOverlay({super.key, required this.game});

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

enum _Fase { dialogo, escolha }

/// Candidatas da primeira escolha: uma por tipo elemental, pra escolha ser
/// escolha de verdade e não só "a única opção".
const List<String> _idsIniciais = [
  'roedor_fogo',
  'tartaruga_planta',
  'sapo_agua',
  'ave_eletrica',
///////////////////
  //'tornado_fogo',
  //'cobra_agua',
  //'urso_planta',
  //'grilo_eletrico',
///////////////////
 // 'bomba_fogo',
 // 'slime_planta',
 // 'pinguim_agua',
 // 'ourico_eletrico',
///////////////////
  //'caranguejo_fogo',
  //'toco_planta',
  //'tubarao_agua',
  //'leao_eletrico',
///////////////////
  //'cao_neutro',
  //'gato_neutro',
  //'ave_neutro',
  //'peixe_neutro',
];

class _IntroOverlayState extends State<IntroOverlay> {
  _Fase _fase = _Fase.dialogo;
  int _pagina = 0;
  int _revelados = 0;
  Timer? _maquina;

  late final List<CreatureData> _candidatas = _idsIniciais
      .map(CreatureRegistry.byId)
      .toList();
  late CreatureData _selecionada = _candidatas.first;

  bool _confirmando = false;

  /// Uma página por toque. Escritas curtas de propósito: a caixa tem altura
  /// fixa (ver [_CaixaDialogo]) porque em landscape de celular a tela tem
  /// ~360dp de altura, e uma caixa que cresce com o texto reproduz o
  /// "BOTTOM OVERFLOWED" que já apareceu no seletor de criaturas.
  List<String> get _paginas => [
    context.l10n.intro_pagina1,
    context.l10n.intro_pagina2,
    context.l10n.intro_pagina3,
    context.l10n.intro_pagina4,
  ];

  String get _textoAtual => _paginas[_pagina];
  bool get _paginaCompleta => _revelados >= _textoAtual.length;

  @override
  void initState() {
    super.initState();
    _iniciarDatilografia();
  }

  @override
  void dispose() {
    _maquina?.cancel();
    super.dispose();
  }

  void _iniciarDatilografia() {
    _maquina?.cancel();
    _revelados = 0;
    _maquina = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_revelados >= _textoAtual.length) {
        timer.cancel();
        return;
      }
      setState(() => _revelados++);
    });
  }

  /// Um toque só faz uma coisa: se o texto ainda está saindo, completa a
  /// página; se já saiu, passa pra próxima. Sem isso o jogador apressado pula
  /// página sem ler.
  void _avancar() {
    if (!_paginaCompleta) {
      _maquina?.cancel();
      setState(() => _revelados = _textoAtual.length);
      return;
    }
    if (_pagina < _paginas.length - 1) {
      setState(() => _pagina++);
      _iniciarDatilografia();
    } else {
      _irParaEscolha();
    }
  }

  void _irParaEscolha() {
    _maquina?.cancel();
    setState(() => _fase = _Fase.escolha);
  }

  /// Grava a escolha e entra na run. A ordem importa: a gravação é um único
  /// `concluirIntro` (flag + unlock juntos), o overlay sai de cena antes do
  /// `startRun`, e o `startRun` é que abre o `BossReveal` — o "VS" aparece
  /// depois da intro, não antes.
  Future<void> _confirmar() async {
    if (_confirmando) return;
    setState(() => _confirmando = true);

    await CreatureProgress.instance.concluirIntro(_selecionada.id);
    widget.game.overlays.remove('Intro');
    widget.game.startRun(_selecionada);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UiTheme.backgroundMenuCor,
      child: SafeArea(
        child: _fase == _Fase.dialogo
            ? _construirDialogo()
            : _construirEscolha(),
      ),
    );
  }

  Widget _construirDialogo() {
    // O GestureDetector vem primeiro no Stack (embaixo) pra que o PULAR,
    // desenhado depois, ganhe o toque na área dele.
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: withBtnSfx(_avancar),
          child: Center(
            child: _CaixaDialogo(
              texto: _textoAtual.substring(0, _revelados),
              mostrarSeta: _paginaCompleta,
              pagina: _pagina,
              total: _paginas.length,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: TextButton(
            onPressed: withBtnSfx(_irParaEscolha),
            child: Text(
              context.l10n.intro_pular,
              style: const TextStyle(
                color: UiTheme.txtCor,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Proporções do mockup, e um layout SÓ — não há mais ramo de retrato e
  /// ramo de paisagem. Entre o título e o botão, a altura disponível é
  /// repartida em três: UM terço pros cartões, DOIS terços pro painel de
  /// detalhe. Como são frações do que sobrar, a mesma tela serve de celular
  /// em pé a janela de desktop sem número mágico nenhum.
  ///
  /// A versão anterior empilhava de dois jeitos diferentes conforme a
  /// orientação, e o painel tinha largura e ALTURA fixas derivadas da largura
  /// da tela (`Responsive.largura(context, 260)` como altura) — era isso que
  /// fazia a proporção mudar de tela pra tela.
  Widget _construirEscolha() {
    final retrato = Responsive.ehRetrato(context);

    // Uma linha, quatro cartões dividindo a largura igualmente.
    //
    // `stretch` AQUI é seguro, ao contrário do que dizia o comentário antigo:
    // naquela versão este `Row` ficava direto numa `Column` de altura
    // ilimitada, e esticar pra infinito derrubava o layout. Agora ele mora
    // dentro de um `Expanded`, que entrega altura fechada — e é o stretch que
    // faz os quatro cartões terem exatamente a mesma altura, como no mockup.
    // Em RETRATO vira grade 2x2; em paisagem segue fileira de quatro.
    //
    // Quatro cartões lado a lado num celular em pé dão um quarto da largura
    // pra cada um, e era isso que espremia sprite e nome. Dois por linha
    // dobram a largura de cada cartão usando a altura que sobra — que em
    // retrato é justamente o que não falta.
    final cartoes = [
      for (final criatura in _candidatas)
        _CartaoCandidata(
          criatura: criatura,
          selecionada: criatura.id == _selecionada.id,
          onTap: () => setState(() => _selecionada = criatura),
        ),
    ];

    final listaCandidatas = retrato
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var linha = 0; linha < 2; linha++) ...[
                if (linha > 0) const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < 2; col++)
                        Expanded(child: cartoes[linha * 2 + col]),
                    ],
                  ),
                ),
              ],
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final c in cartoes) Expanded(child: c)],
          );

    final titulo = Padding(
      padding: EdgeInsets.only(top: retrato ? 12 : 4, bottom: retrato ? 10 : 4),
      child: Text(
        context.l10n.intro_escolhaPrimeira,
        style: const TextStyle(
          color: UiTheme.txtCor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );

    final botao = Padding(
      padding: EdgeInsets.symmetric(vertical: retrato ? 10 : 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: UiTheme.btnCor,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          elevation: 0,
          shape: const BordaDuplaShape(),
        ),
        // Toque no cartão seleciona, este botão confirma: escolha
        // permanente merece dois toques.
        onPressed: withBtnSfx(_confirmando ? null : _confirmar),
        child: Text(
          context.l10n.intro_escolher,
          style: const TextStyle(
            fontSize: 18,
            color: UiTheme.txtCor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulo,
          // Em retrato os cartões viram duas linhas, então pedem mais altura:
          // 1/2 e 1/2 em vez do 1/3 e 2/3 da fileira única.
          Expanded(flex: retrato ? 1 : 1, child: listaCandidatas),
          const SizedBox(height: 8),
          Expanded(
            flex: retrato ? 1 : 2,
            child: _FaixaDetalhe(criatura: _selecionada),
          ),
          // `Center`, senão o `stretch` da `Column` estica o botão pela
          // largura inteira da tela — ele tem o próprio padding e deve ficar
          // só do tamanho do texto.
          Center(child: botao),
        ],
      ),
    );
  }
}

/// Caixa de diálogo de altura fixa. `maxLines` é o que garante isso: sem
/// limite de linhas, uma página mais longa que o previsto estoura a caixa em
/// vez de ser cortada.
class _CaixaDialogo extends StatelessWidget {
  final String texto;
  final bool mostrarSeta;
  final int pagina;
  final int total;

  const _CaixaDialogo({
    required this.texto,
    required this.mostrarSeta,
    required this.pagina,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // 520 é a largura "de design"; `Responsive.largura` encolhe só
          // numa tela menor que isso, nunca cresce além. Altura continua
          // fixa de propósito (ver doc da classe).
          width: Responsive.largura(context, 520),
          height: 116,
          padding: const EdgeInsets.all(12),
          decoration:  BoxDecoration(
            color: UiTheme.backgroundMenuCor,
            borderRadius: BorderRadius.circular(2) ,
            border: BordaDupla(cor: Palette.preto, espessura: 2),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  texto,
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: UiTheme.txtCor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (mostrarSeta)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '▼',
                    style: TextStyle(color: UiTheme.txtCor, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
        //const SizedBox(height: 8),
        //Text(
        //  '${pagina + 1} / $total',
        //  style: const TextStyle(color: Palette.indigo, fontSize: 11, letterSpacing: 2),
        //),
      ],
    );
  }
}

/// Um cartão por candidata: sprite já com a paleta da criatura, nome e tipo.
/// Borda grossa marca a selecionada.
class _CartaoCandidata extends StatelessWidget {
  final CreatureData criatura;
  final bool selecionada;
  final VoidCallback onTap;

  const _CartaoCandidata({
    required this.criatura,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final corTipo = UiTheme.corDoTipo(criatura.tipo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: withBtnSfx(onTap),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            // Seleção marcada por COR da linha de fora, não por espessura: a
            // geometria da borda fica igual nos dois estados, então o
            // conteúdo do cartão não dá um pulo quando a seleção troca.
            border: BordaDupla(
              cor: Palette.preto,
              corExterna: selecionada ? corTipo : null,
              espessura: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // `FittedBox` em vez de calcular o tamanho do sprite na mão: o
              // que sobra de altura depois das duas faixas de baixo depende da
              // fonte e do tamanho da tela, e qualquer conta aqui seria um
              // palpite que estoura em alguma janela.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CreatureSprite(creature: criatura, size: 96),
                ),
              ),
              const SizedBox(height: 4),
              _blocoNome(context, corTipo),
            ],
          ),
        ),
      ),
    );
  }

  /// Caixa preta com o nome em branco e, dentro dela, a etiqueta do tipo:
  /// fundo da cor do elemento, texto e borda pretos.
  Widget _blocoNome(BuildContext context, Color corTipo) {
    return Container(
      color: Palette.preto,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // `FittedBox` por faixa: nome de criatura varia muito de
          // comprimento, e o cartão é um quarto da largura da tela.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              creatureName(context, criatura.id),
              style: const TextStyle(
                color: Palette.branco,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            decoration: BoxDecoration(
              color: corTipo,
              border: Border.all(color: Palette.preto, width: 2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CreatureSelectOverlay.typeLabel(context, criatura.tipo),
                style: const TextStyle(
                  color: UiTheme.txtCor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status e habilidades da candidata, nas proporções do mockup: a caixa
/// preenche o que o chamador der (dois terços da altura, ver
/// `_construirEscolha`) e reparte a largura em **4/10 pros status e 6/10 pras
/// habilidades**, com um fio vertical separando os dois lados.
///
/// A sobra maior vai pras habilidades porque é o lado que tem texto corrido:
/// status são três números de largura previsível, descrição de habilidade não.
class _FaixaDetalhe extends StatelessWidget {
  final CreatureData criatura;

  const _FaixaDetalhe({required this.criatura});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.zero,
        border: BordaDupla(cor: Palette.preto, espessura: 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: _status(context)),
          // O fio. `Container` com largura fixa dentro de um `Row` esticado,
          // em vez de `VerticalDivider`: aquele traz espaçamento e espessura
          // próprios do tema do Material, e aqui o resto da tela é tudo linha
          // preta de 2 a 4px desenhada na mão.
          Container(
            width: 3,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            color: Palette.preto,
          ),
          Expanded(flex: 6, child: _habilidades(context)),
        ],
      ),
    );
  }

  Widget _status(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaStatus(
              context.l10n.intro_saudeRotulo,
              criatura.stats.maxHp.toDouble(),
              TetosStatus.saude,
              Palette.vermelho,
            ),
            _linhaStatus(
              context.l10n.intro_velocidadeRotulo,
              criatura.stats.speed,
              TetosStatus.velocidade,
              Palette.azul,
            ),
            _linhaStatus(
              context.l10n.intro_ataqueRotulo,
              criatura.stats.ataque,
              TetosStatus.ataque,
              Palette.laranja,
            ),
            _linhaStatus(
              context.l10n.intro_evasaoRotulo,
              criatura.stats.evasao,
              TetosStatus.evasao,
              Palette.verde,
            ),
          ],
        ),
      ),
    );
  }

  /// Rótulo em cima, barra embaixo. Empilhado, e não lado a lado, porque
  /// esta coluna tem 4/10 da largura do painel — rótulo e dez segmentos na
  /// mesma linha só caberiam encolhendo os dois.
  Widget _linhaStatus(String rotulo, double valor, double teto, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              color: UiTheme.txtCor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          BarraStatus(valor: valor, teto: teto, cor: cor),
        ],
      ),
    );
  }

  Widget _habilidades(BuildContext context) {
    final slotUm = slotUmDaCriatura(context, criatura);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _placaNome(context),
        const SizedBox(height: 6),
        Flexible(
          child: _caixaHabilidade(slotUm.nome, slotUm.descricao, ehAtaque: true),
        ),
        const SizedBox(height: 5),
        Flexible(
          child: _caixaHabilidade(
            abilityName(context, criatura.ability2),
            abilityDescription(context, criatura.ability2),
            ehAtaque: false,
          ),
        ),
      ],
    );
  }

  /// Placa preta com o nome da criatura escrito na cor do ELEMENTO dela — o
  /// único lugar da tela onde o nome aparece grande, e o que amarra a cor da
  /// etiqueta do cartão à criatura em foco.
  Widget _placaNome(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.preto,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          creatureName(context, criatura.id).toUpperCase(),
          style: TextStyle(
            color: UiTheme.corDoTipo(criatura.tipo),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Uma habilidade: moldura preta, nome em negrito, descrição normal.
  ///
  /// O `FittedBox` de dentro é o que deixa as duas caixas sobreviverem a
  /// descrições de tamanhos bem diferentes sem que uma estoure a outra — a
  /// altura de cada uma vem do `Flexible` do chamador, não do texto.
  Widget _caixaHabilidade(
    String nome,
    String descricao, {
    required bool ehAtaque,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Palette.preto, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      // QUEBRA DE LINHA PRIMEIRO, encolher a fonte só em último caso — e quem
      // faz isso acontecer é o `SizedBox` de largura lá embaixo.
      //
      // Sem ele, o `FittedBox` entrega largura INFINITA ao filho. Com largura
      // infinita um `Text` nunca quebra: ele monta o parágrafo inteiro numa
      // linha só, e o `FittedBox` encolhe o conjunto pra caber — era por isso
      // que diminuir a janela mirrava a fonte em vez de quebrar o texto.
      //
      // Fixando a largura na largura REAL da caixa, o texto quebra sozinho, e
      // o `FittedBox` só tem motivo pra agir se o resultado JÁ QUEBRADO ainda
      // for mais alto que a caixa.
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconeHabilidade(criatura: criatura, ehAtaque: ehAtaque),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    // Desconta o ícone e o respiro dele: o texto só quebra na
                    // largura certa se a conta já contar com o que ele ocupa.
                    width: (constraints.maxWidth - 38).clamp(1.0, double.infinity),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: UiTheme.txtCor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          descricao,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: UiTheme.txtCor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
