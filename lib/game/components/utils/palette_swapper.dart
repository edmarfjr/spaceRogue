import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

class PaletteSwapper {
  /// Cache de imagens já processadas, indexado por caminho + cores.
  /// Guardamos o Future (e não a ui.Image) para que várias chamadas
  /// simultâneas para a mesma combinação compartilhem UM único
  /// processamento de pixels e UMA única textura na GPU.
  static final Map<String, Future<ui.Image>> _cache = {};

  static String _keyFor(
    String imagePath,
    Color light,
    Color dark,
    Color? white,
    Color? black,
  ) =>
      '$imagePath|${light.toARGB32()}|${dark.toARGB32()}'
      '|${white?.toARGB32() ?? -1}|${black?.toARGB32() ?? -1}';

  /// Retorna uma ui.Image (imagem bruta) com as cores trocadas, ideal para SpriteAnimations e recortes.
  static Future<ui.Image> createSwappedImage({
    required String imagePath,
    required Color lightGrayReplacement,
    required Color darkGrayReplacement,
    Color? whiteReplacement,
    Color? blackReplacement,
  }) {
    requests++;

    final key = _keyFor(
      imagePath,
      lightGrayReplacement,
      darkGrayReplacement,
      whiteReplacement,
      blackReplacement,
    );

    return _cache.putIfAbsent(
      key,
      () => _buildSwappedImage(
        imagePath: imagePath,
        lightGrayReplacement: lightGrayReplacement,
        darkGrayReplacement: darkGrayReplacement,
        whiteReplacement: whiteReplacement,
        blackReplacement: blackReplacement,
      ),
    );
  }

  /// Processa as combinações usadas em pleno combate (tiros, explosões,
  /// drops) antes do jogo começar, para que o primeiro tiro não trave.
  static Future<void> warmUp(List<Future<ui.Image>> requests) async {
    await Future.wait(requests);
  }

  static void clearCache() => _cache.clear();

  /// Quantas texturas distintas já foram geradas (útil pra medir o cache).
  static int get cachedImages => _cache.length;

  /// Quantos pedidos de troca de paleta já foram feitos. Antes do cache,
  /// cada pedido gerava um processamento de pixels + uma textura nova.
  static int requests = 0;

  static Future<ui.Image> _buildSwappedImage({
    required String imagePath,
    required Color lightGrayReplacement,
    required Color darkGrayReplacement,
    Color? whiteReplacement,
    Color? blackReplacement,
  }) async {
    final ui.Image originalImage = await Flame.images.load(imagePath);
    final ByteData? byteData = await originalImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Falha ao ler os bytes da imagem');

    final Uint8List pixels = byteData.buffer.asUint8List();

    // Valores padrão que você desenhou (Exemplo: 170 para cinza claro, 85 para escuro)
    // Se no seu desenho o valor for diferente, ajuste estas duas variáveis.
    const int lightGrayValue = 169;
    const int darkGrayValue = 84;
    const int whiteValue = 255;
    const int blackValue = 0;

    final int lightArgb = lightGrayReplacement.toARGB32();
    final int darkArgb = darkGrayReplacement.toARGB32();
    final int? whiteArgb = whiteReplacement?.toARGB32();
    final int? blackArgb = blackReplacement?.toARGB32();

    for (int i = 0; i < pixels.length; i += 4) {
      int r = pixels[i];
      int g = pixels[i + 1];
      int b = pixels[i + 2];
      int a = pixels[i + 3];

      if (a == 0) continue;

      if (r == lightGrayValue && g == lightGrayValue && b == lightGrayValue) {
        _writeRgb(pixels, i, lightArgb);
      }
      else if (r == darkGrayValue && g == darkGrayValue && b == darkGrayValue) {
        _writeRgb(pixels, i, darkArgb);
      } else if (whiteArgb != null && r == whiteValue && g == whiteValue && b == whiteValue) {
        _writeRgb(pixels, i, whiteArgb);
      }
      // Substitui o Preto (Se foi fornecida uma cor)
      else if (blackArgb != null && r == blackValue && g == blackValue && b == blackValue) {
        _writeRgb(pixels, i, blackArgb);
      }
    }

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      pixels,
      originalImage.width,
      originalImage.height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) => completer.complete(img),
    );

    return await completer.future;
  }

  static void _writeRgb(Uint8List pixels, int i, int argb) {
    pixels[i] = (argb >> 16) & 0xFF;
    pixels[i + 1] = (argb >> 8) & 0xFF;
    pixels[i + 2] = argb & 0xFF;
  }
}
