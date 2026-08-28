import 'dart:async';

import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/audio/ui_sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_progress.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/game/overlays/creature_select_overlay.dart';

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

/// Uma página por toque. Escritas curtas de propósito: a caixa tem altura
/// fixa (ver [_CaixaDialogo]) porque em landscape de celular a tela tem
/// ~360dp de altura, e uma caixa que cresce com o texto reproduz o
/// "BOTTOM OVERFLOWED" que já apareceu no seletor de criaturas.
const List<String> _paginas = [
  //'Existe um mundo onde a vida não nasce de carne e osso, mas de fogo, água, planta e relâmpago.',
  //'Chamamos essas vidas de CRIATURAS. Cada uma carrega um elemento — e um jeito próprio de lutar.',
  //'Sob a superfície se abrem as MASMORRAS: andares que se remontam sozinhos, nunca iguais duas vezes.',
  //'Ninguém desce lá sozinho. Quem desce é TREINADOR: você não luta, você comanda quem luta por você.',
  //'Criaturas selvagens podem ser capturadas e entrar no seu grupo. No último andar, algo bem maior espera.',
  //'Mas todo treinador começa com uma só. Escolha bem — ela é a sua primeira parceira.',
  'Sob a superfície se abrem misteriosas MASMORRAS, onde habitam CRIATURAS mais misteriosas ainda.',
  'cada CRIATURA carrega um fragmento da criação, dividida nos 4 elementos: FOGO, ÁGUA, PLANTA e RELÂMPAGO',
  'Cabe a você, O TREINADOR, explorar e capturar todas essas CRIATURAS',
  'Mas é muito perigoso explorar as MASMORRAS sozinho! Escolha seu parceiro nessa jornada.',
];

/// Candidatas da primeira escolha: uma por tipo elemental, pra escolha ser
/// escolha de verdade e não só "a única opção".
const List<String> _idsIniciais = [
  'roedor_fogo',
  'tartaruga_planta',
  'sapo_agua',
  'ave_eletrica',
];

class _IntroOverlayState extends State<IntroOverlay> {
  _Fase _fase = _Fase.dialogo;
  int _pagina = 0;
  int _revelados = 0;
  Timer? _maquina;

  late final List<CreatureData> _candidatas = _idsIniciais.map(CreatureRegistry.byId).toList();
  late CreatureData _selecionada = _candidatas.first;

  bool _confirmando = false;

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
        child: _fase == _Fase.dialogo ? _construirDialogo() : _construirEscolha(),
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
            child: const Text(
              'PULAR',
              style: TextStyle(color: Palette.preto, fontSize: 14, letterSpacing: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirEscolha() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 10),
          child: Text(
            'ESCOLHA SUA PRIMEIRA CRIATURA',
            style: TextStyle(color: Palette.preto, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final criatura in _candidatas)
              _CartaoCandidata(
                criatura: criatura,
                selecionada: criatura.id == _selecionada.id,
                onTap: () => setState(() => _selecionada = criatura),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(child: _FaixaDetalhe(criatura: _selecionada)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
            child: const Text(
              ' ESCOLHER ',
              style: TextStyle(fontSize: 18, color: Palette.preto, fontWeight: FontWeight.bold),
            ),
          ),
        ),
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
          width: 520,
          height: 116,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Palette.branco,
            borderRadius: BorderRadius.zero,
            border: Border.fromBorderSide(BorderSide(color: Palette.preto, width: 2)),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  texto,
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(color: Palette.preto, fontSize: 13, height: 1.4),
                ),
              ),
              if (mostrarSeta)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Text('▼', style: TextStyle(color: Palette.preto, fontSize: 14)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: withBtnSfx(onTap),
        child: Container(
          width: 116,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Palette.preto, width: selecionada ? 4 : 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CreatureSprite(creature: criatura, size: 52),
              const SizedBox(height: 6),
              Text(
                criatura.nome,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Palette.preto,
                  fontSize: 12,
                  fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                CreatureSelectOverlay.typeLabel(criatura.tipo),
                style: const TextStyle(color: Palette.preto, fontSize: 12),
              ),
            ],
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
    return Center(
      child: Container(
        width: 720,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(BorderSide(color: Palette.preto, width: 2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Rotulo('SAÚDE ${criatura.stats.maxHp}',fontSize: 16),
                  _Rotulo('VELOCIDADE ${criatura.stats.speed.toInt()}',fontSize: 16),
                  _Rotulo('ATAQUE ${criatura.stats.ataque.toInt()}',fontSize: 16),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Rotulo('HABILIDADES'),
                  _Rotulo(criatura.ability1.nome,textoD:criatura.ability1.descricao),
                  _Rotulo(criatura.passive.nome,textoD:criatura.passive.descricao),
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
  const _Rotulo(this.texto,{this.textoD = '',this.fontSize=12});

  @override
  Widget build(BuildContext context) {
    return 
    Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style:  TextStyle(color: Palette.preto, fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
        ),
        if (textoD != '')
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            textoD,
            //overflow: TextOverflow.ellipsis,
            style:  TextStyle(color: Palette.preto, fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
    
  }
}
