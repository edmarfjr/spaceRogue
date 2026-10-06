import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Peças compartilhadas pelas duas telas de escolha de criatura: a da intro
/// (`IntroOverlay`) e a do começo de run (`CreatureSelectOverlay`).
///
/// Moram juntas aqui porque os dois rascunhos pedem exatamente os mesmos
/// blocos — etiqueta de tipo, barra de status, ícone de habilidade — e manter
/// duas cópias é como a etiqueta de tipo já tinha começado a divergir.

/// Qualquer sprite do jogo desenhado como widget, com troca de paleta.
///
/// Generaliza o que o `CreatureSprite` fazia só pra criatura: o cache do
/// `PaletteSwapper` é por caminho+cores, então reaproveitar aqui não processa
/// pixel nenhum a mais.
class SpriteUi extends StatelessWidget {
  final String caminho;
  final double tamanho;
  final Color cor1;
  final Color cor2;
  final Color? corBranco;

  const SpriteUi({
    super.key,
    required this.caminho,
    required this.tamanho,
    this.cor1 = Palette.cinza,
    this.cor2 = Palette.cinzaEsc,
    this.corBranco,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: FutureBuilder<ui.Image>(
        future: PaletteSwapper.createSwappedImage(
          imagePath: caminho,
          lightGrayReplacement: cor1,
          darkGrayReplacement: cor2,
          whiteReplacement: corBranco,
        ),
        builder: (context, snapshot) {
          final imagem = snapshot.data;
          // Espaço vazio enquanto carrega, e não um indicador de progresso: a
          // troca de paleta é cache-hit quase sempre, e um rodopio piscando
          // por um quadro chama mais atenção que a ausência do ícone.
          if (imagem == null) return const SizedBox.shrink();
          return RawImage(
            image: imagem,
            width: tamanho,
            height: tamanho,
            // `contain` obrigatório: sem `fit`, o Flutter assume `scaleDown`,
            // que só REDUZ — um sprite de 16x16 ficaria desenhado em 16x16 no
            // canto de uma caixa maior.
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          );
        },
      ),
    );
  }
}

/// Etiqueta do elemento: fundo na cor do tipo, texto e borda pretos.
class EtiquetaTipo extends StatelessWidget {
  final CreatureType tipo;
  final String rotulo;
  final double fontSize;

  const EtiquetaTipo({
    super.key,
    required this.tipo,
    required this.rotulo,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UiTheme.corDoTipo(tipo),
        border: Border.all(color: Palette.preto, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          rotulo,
          style: TextStyle(
            color: UiTheme.txtCor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Barra de status em blocos, no lugar de um número solto.
///
/// Dez segmentos com TETO FIXO por status, e não uma barra normalizada pelo
/// maior valor do elenco: normalizar pelo elenco faria a barra de todo mundo
/// mudar no dia em que uma criatura nova entrasse, e a leitura "esta é forte"
/// deixaria de valer entre uma versão e outra.
///
/// Os tetos (10 / 100 / 10) são folgados de propósito — hoje os valores vão de
/// 4 a 6 de vida, 50 a 90 de velocidade e 1 a 5 de ataque, então sobra espaço
/// pra criatura mais forte que venha depois sem estourar a barra.
class BarraStatus extends StatelessWidget {
  final double valor;
  final double teto;
  final Color cor;

  static const int segmentos = 10;

  const BarraStatus({
    super.key,
    required this.valor,
    required this.teto,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final cheios = (valor / teto * segmentos).round().clamp(0, segmentos);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < segmentos; i++)
          Container(
            width: 7,
            height: 10,
            margin: const EdgeInsets.only(right: 1),
            decoration: BoxDecoration(
              color: i < cheios ? cor : Palette.branco,
              border: Border.all(color: Palette.preto, width: 1),
            ),
          ),
      ],
    );
  }
}

/// Tetos de cada barra. Ficam aqui, e não espalhados nas duas telas, pra que
/// a mesma criatura nunca desenhe barras diferentes em telas diferentes.
class TetosStatus {
  TetosStatus._();
  static const double saude = 10;
  static const double velocidade = 100;
  static const double ataque = 10;

  /// Teto da evasão, em porcento. 50 e não 100 de propósito: com teto de cem,
  /// os 5% padrão não acenderiam nem meio segmento e a barra pareceria
  /// quebrada. Cinquenta já é um valor absurdo de alcançar no jogo.
  static const double evasao = 50;
}

/// Ícone de uma habilidade.
///
/// Não existe arte por habilidade (seriam ~40 sprites), então o ícone sai do
/// que a habilidade É:
///
/// - **habilidade 1** (ataque): o ícone do ELEMENTO da criatura, porque é o
///   elemento que decide o dano dela (ver `typeMultiplier`). Reaproveita as
///   pedras elementais, que já são o símbolo de cada elemento no jogo.
/// - **habilidade 2**: `esquiva` ou `defesa` conforme o [AbilityTipo] — os dois
///   ícones que os botões da Hud já usam, então o jogador chega aqui sabendo
///   o que cada um quer dizer.
class IconeHabilidade extends StatelessWidget {
  final CreatureData criatura;

  /// `true` = habilidade do botão A (ataque), `false` = botão B.
  final bool ehAtaque;

  final double tamanho;

  const IconeHabilidade({
    super.key,
    required this.criatura,
    required this.ehAtaque,
    this.tamanho = 26,
  });

  /// Pedra do elemento. `neutro` não tem pedra — cai no ícone genérico de
  /// ataque, que é exatamente o que "sem elemento" quer dizer.
  static const Map<CreatureType, String> _pedraDoTipo = {
    CreatureType.fogo: 'ui/fogo.png',
    CreatureType.agua: 'ui/agua.png',
    CreatureType.planta: 'ui/planta.png',
    CreatureType.eletrico: 'ui/eletrico.png',
  };

  @override
  Widget build(BuildContext context) {
    final String caminho;
    if (ehAtaque) {
      caminho = _pedraDoTipo[criatura.tipo] ?? 'ui/ataque.png';
    } else {
      caminho = switch (criatura.ability2.tipo) {
        AbilityTipo.esquiva => 'ui/esquiva.png',
        AbilityTipo.defesa => 'ui/defesa.png',
        AbilityTipo.ataque => 'ui/ataque.png',
      };
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.preto, width: 2),
        color: Palette.branco,
      ),
      child: SpriteUi(
        caminho: caminho,
        tamanho: tamanho,
        cor1: UiTheme.corDoTipo(criatura.tipo),
        cor2: UiTheme.corDoTipo2(criatura.tipo),
        corBranco: Palette.branco,
      ),
    );
  }
}
