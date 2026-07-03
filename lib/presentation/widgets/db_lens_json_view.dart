import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';
import '../utils/json_view_utils.dart';

/// Render array baris sebagai JSON pretty-printed dengan syntax highlight.
///
/// Menggantikan pola manual (`SelectableText` + `Scrollbar` berlapis) yang
/// berulang kali ditulis ulang konsumen karena widget ini sebelumnya
/// terkunci privat di dalam sheet baris tunggal.
class DbLensJsonView extends StatelessWidget {
  const DbLensJsonView({
    super.key,
    required this.rows,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Map<String, Object?>> rows;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);
    return SingleChildScrollView(
      padding: padding,
      child: DbLensJsonSyntaxText(
        json: DbLensJsonUtils.encodePrettyArray(rows),
        theme: theme,
      ),
    );
  }
}

/// Teks JSON monospace dengan syntax highlighting.
class DbLensJsonSyntaxText extends StatelessWidget {
  const DbLensJsonSyntaxText({
    super.key,
    required this.json,
    required this.theme,
    this.fontSize = 12.5,
  });

  final String json;
  final DbLensTheme theme;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(children: _buildSpans()),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        height: 1.5,
        color: theme.syntaxDefault,
      ),
    );
  }

  List<TextSpan> _buildSpans() {
    final spans = <TextSpan>[];
    var i = 0;

    while (i < json.length) {
      final ch = json[i];

      if (ch == '"') {
        final start = i;
        i = _readStringEnd(json, i + 1);
        final text = json.substring(start, i);
        final isKey = _isJsonKey(json, i);
        spans.add(TextSpan(
          text: text,
          style: TextStyle(
            color: isKey ? theme.textPrimary : theme.syntaxString,
            fontWeight: isKey ? FontWeight.w600 : FontWeight.normal,
          ),
        ));
        continue;
      }

      if (_isNumberStart(ch)) {
        final start = i;
        i = _readNumberEnd(json, i);
        spans.add(TextSpan(
          text: json.substring(start, i),
          style: TextStyle(color: theme.syntaxNumber),
        ));
        continue;
      }

      if (_matchKeyword(json, i, 'true')) {
        spans.add(TextSpan(
          text: 'true',
          style: TextStyle(color: theme.syntaxBool),
        ));
        i += 4;
        continue;
      }
      if (_matchKeyword(json, i, 'false')) {
        spans.add(TextSpan(
          text: 'false',
          style: TextStyle(color: theme.syntaxBool),
        ));
        i += 5;
        continue;
      }
      if (_matchKeyword(json, i, 'null')) {
        spans.add(TextSpan(
          text: 'null',
          style: TextStyle(
            color: theme.syntaxNull,
            fontStyle: FontStyle.italic,
          ),
        ));
        i += 4;
        continue;
      }

      spans.add(TextSpan(
        text: ch,
        style: TextStyle(color: theme.textMuted),
      ));
      i++;
    }

    return spans;
  }

  static int _readStringEnd(String source, int start) {
    var i = start;
    while (i < source.length) {
      if (source[i] == '\\') {
        i += 2;
        continue;
      }
      if (source[i] == '"') return i + 1;
      i++;
    }
    return source.length;
  }

  static bool _isJsonKey(String source, int afterStringIndex) {
    var i = afterStringIndex;
    while (i < source.length && source[i].trim().isEmpty) {
      i++;
    }
    return i < source.length && source[i] == ':';
  }

  static bool _isNumberStart(String ch) {
    return ch == '-' || (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57);
  }

  static int _readNumberEnd(String source, int start) {
    var i = start;
    if (source[i] == '-') i++;
    while (i < source.length && _isDigitOrDotOrExp(source[i])) {
      i++;
    }
    return i;
  }

  static bool _isDigitOrDotOrExp(String ch) {
    return (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) ||
        ch == '.' ||
        ch == 'e' ||
        ch == 'E' ||
        ch == '+' ||
        ch == '-';
  }

  static bool _matchKeyword(String source, int index, String keyword) {
    if (!source.startsWith(keyword, index)) return false;
    if (index > 0) {
      final before = source[index - 1];
      if (_isIdentifierChar(before)) return false;
    }
    final afterIndex = index + keyword.length;
    if (afterIndex < source.length) {
      final after = source[afterIndex];
      if (_isIdentifierChar(after)) return false;
    }
    return true;
  }

  static bool _isIdentifierChar(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57) ||
        ch == '_';
  }
}
