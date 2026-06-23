import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Teks dengan highlight untuk substring yang cocok dengan [highlight].
class DbLensHighlightedText extends StatelessWidget {
  const DbLensHighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    required this.theme,
    this.style,
    this.highlightStyle,
  });

  final String text;
  final String highlight;
  final DbLensTheme theme;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  @override
  Widget build(BuildContext context) {
    final query = highlight.trim();
    final baseStyle = style ??
        TextStyle(
          color: theme.textSecondary,
          fontSize: 13,
          fontFamily: 'monospace',
          letterSpacing: -0.2,
        );
    final activeStyle = highlightStyle ??
        baseStyle.copyWith(
          color: theme.accent,
          fontWeight: FontWeight.w600,
          backgroundColor: theme.accentSoft,
        );

    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: activeStyle,
      ));
      start = index + query.length;
    }

    return Text.rich(TextSpan(children: spans));
  }
}
