import 'package:flutter/material.dart';

/// Konfigurasi warna dan token desain yang dapat disesuaikan untuk panel DB Lens.
class DbLensThemeData {
  const DbLensThemeData({
    this.bg = const Color(0xFFFFFFFF),
    this.surface = const Color(0xFFF5F7FA),
    this.border = const Color(0xFFE5E7EB),
    this.textPrimary = const Color(0xFF111827),
    this.textSecondary = const Color(0xFF6B7280),
    this.textMuted = const Color(0xFF9CA3AF),
    this.accent = const Color(0xFF6366F1),
    this.accentSoft = const Color(0xFFEEF2FF),
    this.syntaxNull = const Color(0xFF9CA3AF),
    this.syntaxString = const Color(0xFF16A34A),
    this.syntaxNumber = const Color(0xFFD97706),
    this.syntaxBool = const Color(0xFF2563EB),
    this.syntaxDefault = const Color(0xFF111827),
  });

  /// Nilai default — sama dengan token hardcoded asli.
  static const defaults = DbLensThemeData();

  final Color bg;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color syntaxNull;
  final Color syntaxString;
  final Color syntaxNumber;
  final Color syntaxBool;
  final Color syntaxDefault;

  factory DbLensThemeData.fromMaterialTheme(ThemeData theme) {
    final cs = theme.colorScheme;
    return DbLensThemeData(
      bg: const Color(0xFFFFFBF8),
      surface: const Color(0xFFF5F0EB),
      border: const Color(0xFFE8E0D8),
      textPrimary: const Color(0xFF1C1917),
      textSecondary: const Color(0xFF78716C),
      textMuted: const Color(0xFFA8A29E),
      accent: cs.primary,
      accentSoft: cs.primary.withValues(alpha: 0.1),
      syntaxNull: const Color(0xFFA8A29E),
      syntaxString: const Color(0xFF15803D),
      syntaxNumber: const Color(0xFFB45309),
      syntaxBool: const Color(0xFF1D4ED8),
      syntaxDefault: const Color(0xFF1C1917),
    );
  }

  DbLensThemeData copyWith({
    Color? bg,
    Color? surface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentSoft,
    Color? syntaxNull,
    Color? syntaxString,
    Color? syntaxNumber,
    Color? syntaxBool,
    Color? syntaxDefault,
  }) {
    return DbLensThemeData(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      syntaxNull: syntaxNull ?? this.syntaxNull,
      syntaxString: syntaxString ?? this.syntaxString,
      syntaxNumber: syntaxNumber ?? this.syntaxNumber,
      syntaxBool: syntaxBool ?? this.syntaxBool,
      syntaxDefault: syntaxDefault ?? this.syntaxDefault,
    );
  }
}
