import 'package:flutter/material.dart';

/// O que todo item de catálogo sabe dizer sobre si: como se desenha e como se
/// chama. Implementado por [PowerUpType], [ConsumableType] e [ItemEfeito] —
/// três famílias que antes respondiam a essas mesmas seis perguntas em três
/// formatos diferentes.
///
/// Só a APRESENTAÇÃO entra aqui, nunca o efeito. As três famílias divergem em
/// quatro eixos ao mesmo tempo — quando o efeito roda (na coleta / por escolha
/// depois / nunca, só registra gancho), onde o item fica guardado (em lugar
/// nenhum / `Player.slots` / `Player.itens`), se pode repetir na run, e como
/// vai pro save. Um `aplicar` comum aqui viraria um `switch` de família dentro
/// de cada implementação, que é pior de mexer do que as três assinaturas
/// separadas que existem hoje (`void aplicar`, `bool aplicar`, e nenhuma).
///
/// Moeda, coração, XP e bomba NÃO implementam isto de propósito: não têm nome,
/// descrição nem catálogo, e forçá-los aqui encheria a interface de retornos
/// vazios.
abstract interface class ItemDescritor {
  /// Chave estável, usada em save e em comparação. Para os enums é o próprio
  /// `name` — que JÁ é o que o save grava (`'slots'`), então renomear um valor
  /// do enum quebra saves existentes.
  String get id;

  String get spritePath;
  Color get cor1;
  Color get cor2;

  /// Nome curto, usado no rótulo acima do sprite no chão.
  String nome(BuildContext context);

  /// Texto mais longo: o que o item faz. Vai pro balcão da loja e pro aviso
  /// que sobe quando o efeito acontece.
  String descricao(BuildContext context);
}
