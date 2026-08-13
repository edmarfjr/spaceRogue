import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

class PaletteSwapper {
  /// Retorna uma ui.Image (imagem bruta) com as cores trocadas, ideal para SpriteAnimations e recortes.
  static Future<ui.Image> createSwappedImage({
    required String imagePath,
    required Color lightGrayReplacement,
    required Color darkGrayReplacement,
  }) async {
    final ui.Image originalImage = await Flame.images.load(imagePath);
    final ByteData? byteData = await originalImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Falha ao ler os bytes da imagem');

    final Uint8List pixels = byteData.buffer.asUint8List();

    // Valores padrão que você desenhou (Exemplo: 170 para cinza claro, 85 para escuro)
    // Se no seu desenho o valor for diferente, ajuste estas duas variáveis.
    const int lightGrayValue = 169; 
    const int darkGrayValue = 84;   

    for (int i = 0; i < pixels.length; i += 4) {
      int r = pixels[i];
      int g = pixels[i + 1];
      int b = pixels[i + 2];
      int a = pixels[i + 3];

      if (a == 0) continue; 

      if (r == lightGrayValue && g == lightGrayValue && b == lightGrayValue) {
        pixels[i] = lightGrayReplacement.red;
        pixels[i + 1] = lightGrayReplacement.green;
        pixels[i + 2] = lightGrayReplacement.blue;
      }
      else if (r == darkGrayValue && g == darkGrayValue && b == darkGrayValue) {
        pixels[i] = darkGrayReplacement.red;
        pixels[i + 1] = darkGrayReplacement.green;
        pixels[i + 2] = darkGrayReplacement.blue;
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
}