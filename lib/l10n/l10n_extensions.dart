import 'package:flutter/widgets.dart';
import 'gen/app_localizations.dart';

/// Atalho pra não repetir `AppLocalizations.of(context)!` em cada tela.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
