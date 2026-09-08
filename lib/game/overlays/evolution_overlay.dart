import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/l10n/creature_i18n.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import '../audio/ui_sfx.dart';

/// Cerimônia de evolução (ver PIVOT_EVOLUCAO): o jogo já pausou e já trocou
/// os dados por baixo (`Player._evoluir`) — esta tela é só a encenação.
///
/// Sequência (uma `AnimationController` só, dividida em trechos):
/// 1. `_fechando` (0–30%): círculo vermelho fecha até o centro sobre o
///    sprite BASE — o que o círculo ainda não cobre mostra o sprite; o
///    resto já é vermelho.
/// 2. `_flashBranco` (30–40%): fechou de vez (raio 0, sprite 100% coberto)
///    — troca o fundo pra branco ("toda a sprite fica branca"). O sprite é
///    trocado pro EVOLUÍDO aqui, escondido atrás do branco.
/// 3. `_abrindo` (40–70%): fundo volta a vermelho, círculo reabre — revela
///    o sprite evoluído aos poucos.
/// 4. `_assentando` (70–100%): já revelado; um resíduo branco esmaece,
///    "as cores voltam ao normal".
///
/// Só depois de tudo isso o diálogo "continuar" aparece.
class EvolutionOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const EvolutionOverlay({super.key, required this.game});

  @override
  State<EvolutionOverlay> createState() => _EvolutionOverlayState();
}

class _EvolutionOverlayState extends State<EvolutionOverlay>
    with SingleTickerProviderStateMixin {
  static const double _boxSize = 96;
  static const double _raioMax = 70; // cobre a caixa inteira (diagonal/2 ≈ 68)

  late final AnimationController _controle;
  ui.Image? _imgBase;
  ui.Image? _imgEvoluida;
  bool _prontaParaAnimar = false;
  bool _mostrarContinuar = false;

  @override
  void initState() {
    super.initState();
    _controle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addListener(() => setState(() {}));

    _controle.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _mostrarContinuar = true);
      }
    });

    _carregarSprites();
  }

  Future<void> _carregarSprites() async {
    final base = widget.game.evolucaoBase;
    final nova = widget.game.evolucaoNova;
    if (base == null || nova == null) return;

    final resultados = await Future.wait([
      PaletteSwapper.createSwappedImage(
        imagePath: base.spritePath,
        lightGrayReplacement: base.corClara,
        darkGrayReplacement: base.corEscura,
      ),
      PaletteSwapper.createSwappedImage(
        imagePath: nova.spritePath,
        lightGrayReplacement: nova.corClara,
        darkGrayReplacement: nova.corEscura,
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _imgBase = resultados[0];
      _imgEvoluida = resultados[1];
      _prontaParaAnimar = true;
    });
    _controle.forward();
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nova = widget.game.evolucaoNova;

    return Material(
      color: Palette.preto.withAlpha(200),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Palette.branco,
            border: Border.all(color: Palette.preto, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.evolution_titulo,
                style: const TextStyle(
                  color: Palette.preto,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: _boxSize,
                height: _boxSize,
                child: _prontaParaAnimar
                    ? _buildAnimacao()
                    : const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black45,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              if (nova != null)
                Text(
                  creatureName(context, nova.id),
                  style: const TextStyle(
                    color: Palette.preto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: _mostrarContinuar
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.branco,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(color: Palette.preto, width: 2),
                          ),
                        ),
                        onPressed: withBtnSfx(widget.game.dismissEvolucao),
                        child: Text(
                          context.l10n.pause_continuar,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Palette.preto,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimacao() {
    final t = _controle.value;

    // Trechos da sequência — ver doc da classe.
    const fimFechando = 0.30;
    const fimFlash = 0.40;
    const fimAbrindo = 0.70;

    late final double raio;
    late final Color fundo;
    late final bool mostraEvoluida;
    late final double opacidadeResiduo;

    if (t < fimFechando) {
      final progresso = t / fimFechando;
      raio = _raioMax * (1 - progresso);
      fundo = Palette.branco;
      mostraEvoluida = false;
      opacidadeResiduo = 0;
    } else if (t < fimFlash) {
      raio = 0;
      fundo = Palette.branco;
      mostraEvoluida = true; // já escondida atrás do branco
      opacidadeResiduo = 0;
    } else if (t < fimAbrindo) {
      final progresso = (t - fimFlash) / (fimAbrindo - fimFlash);
      raio = _raioMax * progresso;
      fundo = Palette.branco;
      mostraEvoluida = true;
      opacidadeResiduo = 0;
    } else {
      final progresso = (t - fimAbrindo) / (1 - fimAbrindo);
      raio = _raioMax;
      fundo = Palette.branco;
      mostraEvoluida = true;
      opacidadeResiduo = (1 - progresso).clamp(0.0, 1.0) * 0.6;
    }

    final imagem = mostraEvoluida ? _imgEvoluida : _imgBase;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: _boxSize, height: _boxSize, color: fundo),
        ClipPath(
          clipper: _CirculoClipper(raio, Offset(_boxSize / 2, _boxSize / 2)),
          child: SizedBox(
            width: _boxSize,
            height: _boxSize,
            child: imagem == null
                ? null
                : RawImage(
                    image: imagem,
                    // Sem `width`/`height`, RawImage desenha no tamanho
                    // NATIVO da imagem (16x16/24x24), ignorando o SizedBox —
                    // mesma pegadinha que `CreatureSprite` já documenta.
                    width: _boxSize,
                    height: _boxSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
          ),
        ),
        if (opacidadeResiduo > 0)
          Opacity(
            opacity: opacidadeResiduo,
            child: Container(
              width: _boxSize,
              height: _boxSize,
              color: Palette.branco,
            ),
          ),
      ],
    );
  }
}

class _CirculoClipper extends CustomClipper<Path> {
  final double raio;
  final Offset centro;

  _CirculoClipper(this.raio, this.centro);

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: centro, radius: raio));

  @override
  bool shouldReclip(covariant _CirculoClipper oldClipper) =>
      oldClipper.raio != raio;
}
