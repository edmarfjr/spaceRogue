import 'package:creatures_rogue/game/components/core/ui_theme.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'package:creatures_rogue/l10n/creature_i18n.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import '../audio/ui_sfx.dart';

/// Cerimônia de aposentadoria — a criatura evoluída encheu a segunda barra de
/// XP e deixa o grupo de vez, trocada por uma passiva permanente.
///
/// Mesmo molde da `EvolutionOverlay` (diálogo com uma janela preta de
/// animação e um "continuar" que só aparece no fim), mas a sequência é de
/// despedida, não de transformação. Uma `AnimationController` só, dividida em
/// trechos por tempo:
///
/// 1. `_msFechando`: circunferência BRANCA fecha do raio aberto até um ponto
///    no centro, com o sprite em cores normais.
/// 2. `_msSumindo`: o sprite já está branco sólido e some (alpha vai a zero),
///    deixando só um pequeno círculo branco cheio no centro.
/// 3. `_msSubindo`: esse círculo sobe rápido e sai pelo topo da janela.
///
/// IMPORTANTE: nada de estado do jogo muda aqui. Quem entrega a passiva,
/// libera o slot e eventualmente dispara o Game Over é
/// `CreaturesRogueGame.dismissAposentadoria`, no toque de continuar — é isso
/// que faz o texto do prêmio e a tela de fim aparecerem DEPOIS da animação.
class RetirementOverlay extends StatefulWidget {
  final CreaturesRogueGame game;
  const RetirementOverlay({super.key, required this.game});

  @override
  State<RetirementOverlay> createState() => _RetirementOverlayState();
}

class _RetirementOverlayState extends State<RetirementOverlay>
    with SingleTickerProviderStateMixin {
  static const double _boxSize = 120;

  /// Raio da circunferência "aberta" — onde o fechamento começa.
  static const double _raioAnel = 62.0;

  /// Raio do ponto que sobra no centro depois de o sprite sumir.
  static const double _raioPonto = 5.0;

  static const int _msFechando = 900;
  static const int _msSumindo = 400;
  static const int _msSubindo = 350;
  static const int _msTotal = _msFechando + _msSumindo + _msSubindo;

  /// Fração final do fechamento em que o sprite já está virando branco. O
  /// branco não espera o anel fechar: ele acompanha o aperto, senão a virada
  /// pra branco viria como um corte seco.
  static const double _inicioBranco = 0.6;

  late final AnimationController _controle;
  ui.Image? _img;
  bool _prontaParaAnimar = false;
  bool _mostrarContinuar = false;

  @override
  void initState() {
    super.initState();
    _controle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _msTotal),
    )..addListener(() => setState(() {}));

    _controle.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _mostrarContinuar = true);
      }
    });

    _carregarSprite();
  }

  Future<void> _carregarSprite() async {
    final criatura = widget.game.aposentadoriaCriatura;
    if (criatura == null) return;

    final img = await PaletteSwapper.createSwappedImage(
      imagePath: criatura.spritePath,
      lightGrayReplacement: criatura.corClara,
      darkGrayReplacement: criatura.corEscura,
    );

    if (!mounted) return;
    setState(() {
      _img = img;
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
    final criatura = widget.game.aposentadoriaCriatura;
    final passiva = widget.game.aposentadoriaPassiva;

    return Material(
      color: Palette.preto.withAlpha(200),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Palette.preto,
            border: const BordaDupla(cor: Palette.branco, espessura: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.retirement_titulo,
                style: const TextStyle(
                  color: Palette.branco,
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
                          color: Palette.branco,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              if (criatura != null)
                Text(
                  creatureName(context, criatura.id),
                  style: const TextStyle(
                    color: Palette.branco,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              // Nome e descrição da passiva já aqui, e não só no texto que
              // sobe depois: esta tela é onde o jogador está olhando quando
              // recebe o prêmio.
              if (passiva != null && _mostrarContinuar) ...[
                const SizedBox(height: 8),
                Text(
                  passiva.nome(context),
                  style: const TextStyle(
                    color: Palette.amarelo,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: _boxSize + 40,
                  child: Text(
                    passiva.descricao(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Palette.branco,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
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
                        onPressed: withBtnSfx(
                          widget.game.dismissAposentadoria,
                        ),
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
    final tMs = _controle.value * _msTotal;
    final centro = Offset(_boxSize / 2, _boxSize / 2);

    late final double raioAnel;
    late final double alphaBranco; // 0 = cores normais, 1 = branco sólido
    late final double opacidadeSprite;
    late final double raioPonto;
    late final Offset centroPonto;

    if (tMs < _msFechando) {
      final progresso = tMs / _msFechando;
      raioAnel = _raioAnel + (_raioPonto - _raioAnel) * progresso;
      alphaBranco = progresso < _inicioBranco
          ? 0.0
          : (progresso - _inicioBranco) / (1 - _inicioBranco);
      opacidadeSprite = 1.0;
      raioPonto = 0.0;
      centroPonto = centro;
    } else if (tMs < _msFechando + _msSumindo) {
      final progresso = (tMs - _msFechando) / _msSumindo;
      // O anel virou o ponto: para de desenhar o contorno e o ponto cheio
      // assume, crescendo do zero enquanto o sprite esmaece.
      raioAnel = 0.0;
      alphaBranco = 1.0;
      opacidadeSprite = 1 - progresso;
      raioPonto = _raioPonto * progresso;
      centroPonto = centro;
    } else {
      final progresso = ((tMs - _msFechando - _msSumindo) / _msSubindo).clamp(
        0.0,
        1.0,
      );
      raioAnel = 0.0;
      alphaBranco = 1.0;
      opacidadeSprite = 0.0;
      raioPonto = _raioPonto;
      // Acelera subindo (`easeIn`) e passa do topo da janela — o `ClipRect`
      // corta, então ele sai de cena em vez de encostar na borda e parar.
      final subida = Curves.easeIn.transform(progresso);
      centroPonto = Offset(
        centro.dx,
        centro.dy - (centro.dy + _raioPonto * 2) * subida,
      );
    }

    final imagem = _img;

    return ClipRect(
      child: Container(
        width: _boxSize,
        height: _boxSize,
        color: Palette.preto,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: opacidadeSprite.clamp(0.0, 1.0),
              child: ColorFiltered(
                // Alpha 255 tinge tudo de branco preservando o formato (alfa)
                // da imagem — silhueta sólida branca. Ver `srcATop`.
                colorFilter: ColorFilter.mode(
                  Palette.branco.withAlpha(
                    (alphaBranco.clamp(0.0, 1.0) * 255).round(),
                  ),
                  BlendMode.srcATop,
                ),
                child: SizedBox(
                  width: _boxSize,
                  height: _boxSize,
                  child: imagem == null
                      ? null
                      : RawImage(
                          image: imagem,
                          // `width`/`height` + `contain` obrigatórios: a forma
                          // evoluída é 24x24 e sem isso `RawImage` a desenha
                          // no tamanho nativo, minúscula na janela de 120.
                          width: _boxSize,
                          height: _boxSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(_boxSize, _boxSize),
              painter: _DespedidaPainter(
                raioAnel: raioAnel,
                centroAnel: centro,
                raioPonto: raioPonto,
                centroPonto: centroPonto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha as duas peças brancas da cena: a circunferência OCA que se fecha e
/// o ponto CHEIO que sobra e sobe. Raio zero em qualquer das duas não desenha
/// nada — evita traço degenerado no quadro exato da troca de fase.
class _DespedidaPainter extends CustomPainter {
  final double raioAnel;
  final Offset centroAnel;
  final double raioPonto;
  final Offset centroPonto;

  static const double _espessura = 4;

  _DespedidaPainter({
    required this.raioAnel,
    required this.centroAnel,
    required this.raioPonto,
    required this.centroPonto,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (raioAnel > 0) {
      canvas.drawCircle(
        centroAnel,
        raioAnel,
        Paint()
          ..color = Palette.branco
          ..style = PaintingStyle.stroke
          ..strokeWidth = _espessura,
      );
    }

    if (raioPonto > 0) {
      canvas.drawCircle(
        centroPonto,
        raioPonto,
        Paint()..color = Palette.branco,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DespedidaPainter oldDelegate) =>
      oldDelegate.raioAnel != raioAnel ||
      oldDelegate.raioPonto != raioPonto ||
      oldDelegate.centroPonto != centroPonto;
}
