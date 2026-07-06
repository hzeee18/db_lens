import 'package:flutter/material.dart';

import '../hooks/db_lens_cell_editor_builder.dart';
import '../theme/db_lens_theme.dart';

/// Default type-aware cell edit dialog with type badge and validation.
class DbLensCellEditor extends StatefulWidget {
  const DbLensCellEditor({
    super.key,
    required this.column,
    required this.currentValue,
    this.isSQLite = true,
    this.theme,
  });

  final String column;
  final Object? currentValue;
  final bool isSQLite;
  final DbLensTheme? theme;

  /// Shows the dialog. Throws [DbLensCellEditCancelled] when dismissed.
  static Future<Object?> show(
    BuildContext context,
    String column,
    Object? currentValue, {
    bool isSQLite = true,
    DbLensTheme? theme,
  }) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => DbLensCellEditor(
        column: column,
        currentValue: currentValue,
        isSQLite: isSQLite,
        theme: theme,
      ),
    );
    if (result == null || result.cancelled) {
      throw const DbLensCellEditCancelled();
    }
    return result.value;
  }

  @override
  State<DbLensCellEditor> createState() => _DbLensCellEditorState();
}

class _EditResult {
  const _EditResult({required this.value, this.cancelled = false});

  static const cancel = _EditResult(value: null, cancelled: true);

  final Object? value;
  final bool cancelled;
}

class _DbLensCellEditorState extends State<DbLensCellEditor> {
  late final TextEditingController _controller;
  late bool _boolValue;
  String? _validationError;

  bool get _isBool => widget.currentValue is bool;
  bool get _isInt => widget.currentValue is int;
  bool get _isDouble => widget.currentValue is double && widget.currentValue is! int;
  bool get _isNum => widget.currentValue is num && widget.currentValue is! bool;
  bool get _isNull => widget.currentValue == null;

  String get _typeLabel {
    final value = widget.currentValue;
    if (value == null) return 'null';
    if (value is bool) return 'Boolean';
    if (value is int) return 'Integer';
    if (value is double) return 'Double';
    if (value is num) return 'Number';
    return 'String';
  }

  @override
  void initState() {
    super.initState();
    _boolValue = widget.currentValue is bool ? widget.currentValue! as bool : false;
    _controller = TextEditingController(
      text: _isBool ? '' : (widget.currentValue?.toString() ?? ''),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Object? _parseAndValidate() {
    final raw = _controller.text.trim();
    if (_isBool) return _boolValue;

    if (_isInt) {
      final parsed = int.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Must be a whole number (integer).');
        return null;
      }
      return parsed;
    }

    if (_isDouble) {
      final parsed = double.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Must be a decimal number.');
        return null;
      }
      return parsed;
    }

    if (_isNum) {
      final parsed = num.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Must be a number.');
        return null;
      }
      return parsed;
    }

    if (_isNull && raw.isEmpty) return null;
    return raw;
  }

  void _save() {
    setState(() => _validationError = null);
    final value = _parseAndValidate();
    if (_validationError != null) return;
    Navigator.pop(context, _EditResult(value: value));
  }

  InputDecoration _fieldDecoration(DbLensTheme theme) {
    final borderColor = _validationError != null ? Colors.redAccent : theme.border;
    final focusedColor = _validationError != null ? Colors.redAccent : theme.accent;

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: _isNull ? '(empty = null)' : null,
      hintStyle: TextStyle(color: theme.textMuted, fontSize: 12),
      isDense: true,
      filled: true,
      fillColor: theme.surface,
      contentPadding: const EdgeInsets.all(12),
      border: border(borderColor),
      enabledBorder: border(borderColor),
      focusedBorder: border(focusedColor, width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? DbLensThemeScope.of(context);

    return AlertDialog(
      backgroundColor: theme.bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit: ${widget.column}',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TypeBadge(label: _typeLabel, theme: theme),
              if (!widget.isSQLite)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SharedPreferences — type cannot be changed',
                    style: TextStyle(color: theme.accent, fontSize: 10),
                  ),
                ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          if (_isBool)
            Row(
              children: [
                Text('Value', style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                const Spacer(),
                Switch(
                  value: _boolValue,
                  activeThumbColor: theme.accent,
                  activeTrackColor: theme.accentSoft,
                  onChanged: (v) => setState(() => _boolValue = v),
                ),
                Text(
                  _boolValue ? 'true' : 'false',
                  style: TextStyle(
                    color: _boolValue ? theme.syntaxBool : theme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: _isNull || (!_isNum && !_isBool) ? 3 : 1,
              keyboardType: _isNum
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.multiline,
              onChanged: (_) {
                if (_validationError != null) setState(() => _validationError = null);
              },
              style: TextStyle(
                fontSize: 13,
                color: theme.textPrimary,
                fontFamily: 'monospace',
              ),
              decoration: _fieldDecoration(theme),
            ),
          if (_validationError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 13, color: Colors.redAccent),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _EditResult.cancel),
          child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: theme.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.theme});

  final String label;
  final DbLensTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
