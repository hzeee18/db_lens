import 'package:flutter/material.dart';

import 'db_lens_theme_data.dart';

/// Instance tema yang dapat dikonfigurasi untuk panel DB Lens.
class DbLensTheme {
  DbLensTheme([DbLensThemeData? data]) : data = data ?? DbLensThemeData.defaults;

  final DbLensThemeData data;

  Color get bg => data.bg;
  Color get surface => data.surface;
  Color get border => data.border;
  Color get textPrimary => data.textPrimary;
  Color get textSecondary => data.textSecondary;
  Color get textMuted => data.textMuted;
  Color get accent => data.accent;
  Color get accentSoft => data.accentSoft;
  Color get syntaxNull => data.syntaxNull;
  Color get syntaxString => data.syntaxString;
  Color get syntaxNumber => data.syntaxNumber;
  Color get syntaxBool => data.syntaxBool;
  Color get syntaxDefault => data.syntaxDefault;

  static const headerFontSize = 11.0;
  static const dataFontSize = 12.5;
  static const cellPaddingH = 14.0;
  static const cellPaddingV = 10.0;
  static const cellMinWidth = 110.0;
  static const indexColWidth = 44.0;

  static const initialChildSize = 0.92;
  static const minChildSize = 0.4;
  static const maxChildSize = 1.0;
  static const dismissThreshold = 0.45;

  static const sheetRadius = Radius.circular(14);
  static const sheetShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 24,
    offset: Offset(0, -4),
  );

  BoxDecoration sheetDecoration({double size = 0}) {
    final isFull = size >= 1.0;
    return BoxDecoration(
      color: bg,
      borderRadius: isFull
          ? null
          : const BorderRadius.vertical(top: sheetRadius),
      border: isFull
          ? null
          : Border(
              top: BorderSide(color: border),
              left: BorderSide(color: border),
              right: BorderSide(color: border),
            ),
      boxShadow: isFull ? null : const [sheetShadow],
    );
  }

  OutlineInputBorder outlineBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color ?? border),
    );
  }

  InputDecoration fieldDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: textSecondary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: fillColor ?? surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: outlineBorder(),
      enabledBorder: outlineBorder(color: border),
      focusedBorder: outlineBorder(color: accent),
    );
  }
}

/// Menyediakan [DbLensTheme] ke subtree widget panel.
class DbLensThemeScope extends InheritedWidget {
  const DbLensThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final DbLensTheme theme;

  static DbLensTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DbLensThemeScope>();
    return scope?.theme ?? DbLensTheme();
  }

  @override
  bool updateShouldNotify(DbLensThemeScope oldWidget) =>
      theme.data != oldWidget.theme.data;
}
