import 'package:flutter/material.dart';

/// Shared design tokens for the DB Lens panel (Notion / Linear light mode).
abstract final class DbLensTheme {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F7FA);
  static const border = Color(0xFFE5E7EB);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const accent = Color(0xFF6366F1);
  static const accentSoft = Color(0xFFEEF2FF);

  static const syntaxNull = Color(0xFF9CA3AF);
  static const syntaxString = Color(0xFF16A34A);
  static const syntaxNumber = Color(0xFFD97706);
  static const syntaxBool = Color(0xFF2563EB);
  static const syntaxDefault = Color(0xFF111827);

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

  static BoxDecoration sheetDecoration({double size = 0}) {
    final isFull = size >= 1.0;
    return BoxDecoration(
      color: bg,
      borderRadius: isFull
          ? null
          : const BorderRadius.vertical(top: sheetRadius),
      border: isFull
          ? null
          : const Border(
              top: BorderSide(color: border),
              left: BorderSide(color: border),
              right: BorderSide(color: border),
            ),
      boxShadow: isFull ? null : const [sheetShadow],
    );
  }

  static OutlineInputBorder outlineBorder({Color color = border}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
  }

  static InputDecoration fieldDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = surface,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textSecondary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: outlineBorder(),
      enabledBorder: outlineBorder(color: border),
      focusedBorder: outlineBorder(color: accent),
    );
  }
}
