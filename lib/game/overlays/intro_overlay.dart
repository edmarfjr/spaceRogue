import 'dart:async';

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/UI/dynamic_joystick_component.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/responsive.dart';
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
      color: Palette.branco,
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
                color: Palette.preto,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirEscolha() {
    final tela = MediaQuery.sizeOf(context);
    final retrato = DynamicJoystickComponent.retrato(
      Vector2(tela.width, tela.height),
    );

    // Uma linha só, cada cartão dividindo a largura disponível igualmente —
    // nem `Wrap` (quebrava em 2 linhas com espaço morto nas pontas) nem
    // largura fixa por cartão (era isso que forçava a fonte do nome a
    // encolher pra caber). A largura disponível muda com o modo (ver
    // branches abaixo), o cartão mesmo é sempre "preencha o que te derem".
    //
    // SEM `crossAxisAlignment: stretch` aqui: em RETRATO este `Row` fica
    // direto dentro da `Column` de fora, que dá altura DESLIMITADA (0 a
    // Infinity) pra filho sem `Expanded` — "stretch" tentando esticar os
    // cartões pra uma altura infinita derrubava o layout inteiro
    // ("RenderFlex... can't have infinite height"). Sem stretch, o cartão
    // só usa a altura do próprio conteúdo, e isso é seguro nos dois modos.
    final listaCandidatas = Row(
      children: [
        for (final criatura in _candidatas)
          Expanded(
            child: _CartaoCandidata(
              criatura: criatura,
              selecionada: criatura.id == _selecionada.id,
              onTap: () => setState(() => _selecionada = criatura),
            ),
          ),
      ],
    );

    final titulo = Padding(
      padding: EdgeInsets.only(top: retrato ? 12 : 4, bottom: retrato ? 10 : 4),
      child: Text(
        context.l10n.intro_escolhaPrimeira,
        style: const TextStyle(
          color: Palette.preto,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final botao = Padding(
      padding: EdgeInsets.only(bottom: retrato ? 10 : 4, top: retrato ? 0 : 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.branco,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Palette.preto, width: 2),
          ),
        ),
        // Toque no cartão seleciona, este botão confirma: escolha
        // permanente merece dois toques.
        onPressed: withBtnSfx(_confirmando ? null : _confirmar),
        child: Text(
          context.l10n.intro_escolher,
          style: const TextStyle(
            fontSize: 18,
            color: Palette.preto,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (retrato) {
      return Column(
        children: [
          titulo,
          // A lista ocupa a largura da TELA (menos o padding do `SafeArea`)
          // — só o `Row` acima já faz isso sozinho, não precisa de mais
          // nada aqui.
          listaCandidatas,
          const SizedBox(height: 10),
          // `Center`, não `Expanded` direto no `_FaixaDetalhe`: só o
          // `Expanded` sozinho fazia a caixa esticar pra preencher TODA a
          // altura que sobrasse — numa tela bem alta virava uma caixa
          // enorme quase vazia. O `Expanded` aqui fora só reserva o espaço
          // (mantém o botão ESCOLHER onde já estava), o `Center` deixa a
          // sobra como respiro em vez de esticar a caixa.
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _FaixaDetalhe(criatura: _selecionada),
              ),
            ),
          ),
          const SizedBox(height: 8),
          botao,
        ],
      );
    }

    // PAISAGEM: lista e caixa de detalhe lado a lado — a lista ocupa o que
    // sobra da largura depois da caixa (capada em 360, mais estreita que o
    // teto de 480 do retrato porque aqui ela empresta altura da TELA
    // TODA, não só de uma faixa embaixo dos cartões — sobra menos altura
    // pra caber o mesmo conteúdo). `Expanded` em volta do `Row`, não
    // `Column` com `SizedBox`/`Center` espalhados: era esse empilhamento
    // vertical (cartões, depois a caixa inteira, cada um com seu próprio
    // respiro) que deixava tanto vão em branco na paisagem.
    return Column(
      children: [
        titulo,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Center(child: listaCandidatas)),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _FaixaDetalhe(criatura: _selecionada),
              ),
            ],
          ),
        ),
        botao,
      ],
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
          decoration: const BoxDecoration(
            color: Palette.branco,
            borderRadius: BorderRadius.zero,
            border: Border.fromBorderSide(
              BorderSide(color: Palette.preto, width: 2),
            ),
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
                    color: Palette.preto,
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
                    style: TextStyle(color: Palette.preto, fontSize: 14),
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

  static const double _padding = 4;

  const _CartaoCandidata({
    required this.criatura,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: withBtnSfx(onTap),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: _padding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: Palette.preto,
              width: selecionada ? 4 : 2,
            ),
          ),
          // O cartão agora preenche o que o `Expanded` do chamador der —
          // sem largura fixa pra alimentar o `SizedBox` do `FittedBox`
          // abaixo, precisa medir a largura de verdade em tempo real
          // (mesma pegadinha documentada em `_FaixaDetalhe`: sem isso o
          // `FittedBox` mede a largura intrínseca do texto e nunca
          // encolhe/cresce com o cartão).
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largura = constraints.maxWidth;
              // Sprite acompanha o cartão (mais espaço = sprite maior),
              // com teto pra não ficar gigante numa lista bem larga.
              final tamanhoSprite = (largura * 0.55).clamp(48.0, 96.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CreatureSprite(creature: criatura, size: tamanhoSprite),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: largura,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        creatureName(context, criatura.id),
                        style: TextStyle(
                          color: Palette.preto,
                          fontSize: 14,
                          fontWeight: selecionada
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: largura,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CreatureSelectOverlay.typeLabel(context, criatura.tipo),
                        style: const TextStyle(
                          color: Palette.preto,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Status e habilidades da candidata selecionada. Fica fora dos cartões pra
/// não empilhar quatro blocos de texto numa tela de ~360dp de altura.
class _FaixaDetalhe extends StatelessWidget {
  final CreatureData criatura;

  const _FaixaDetalhe({required this.criatura});

  @override
  Widget build(BuildContext context) {
    // Sem `Center`/largura fixa aqui dentro: quem chama decide o teto de
    // largura E se isto fica centralizado (retrato, sobra vertical) ou
    // esticado pra preencher a altura (paisagem, lado a lado com a lista) —
    // ver `_construirEscolha`. `Center` interno no `Row` só centraliza o
    // BLOCO de stats/habilidades verticalmente quando a caixa fica mais
    // alta que o conteúdo precisa (a esticada da paisagem), em vez de
    // deixar tudo colado no topo com um vão embaixo.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(
          BorderSide(color: Palette.preto, width: 2),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Rotulo(
                    context.l10n.intro_saude(criatura.stats.maxHp),
                    fontSize: 16,
                  ),
                  _Rotulo(
                    context.l10n.intro_velocidade(criatura.stats.speed.toInt()),
                    fontSize: 16,
                  ),
                  _Rotulo(
                    context.l10n.intro_ataque(criatura.stats.ataque.toInt()),
                    fontSize: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Rotulo(context.l10n.intro_habilidades),
                  _Rotulo(
                    abilityName(context, criatura.ability1),
                    textoD: abilityDescription(context, criatura.ability1),
                  ),
                  _Rotulo(
                    abilityName(context, criatura.ability2),
                    textoD: abilityDescription(context, criatura.ability2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;
  final String textoD;
  final double fontSize;
  const _Rotulo(this.texto, {this.textoD = '', this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Palette.preto,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (textoD != '')
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              textoD,
              //overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Palette.preto,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
