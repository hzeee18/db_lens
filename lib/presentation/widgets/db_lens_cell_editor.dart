import 'package:flutter/material.dart';

import '../hooks/db_lens_cell_editor_builder.dart';
import '../theme/db_lens_theme.dart';

/// Dialog edit sel bawaan — input type-aware (bool/int/double/string) dengan
/// validasi inline. Dipanggil lewat [show], yang juga jadi implementasi
/// default dari [DbLensCellEditorBuilder].
class DbLensCellEditor extends StatefulWidget {
  const DbLensCellEditor({
    super.key,
    required this.column,
    required this.currentValue,
    this.theme,
  });

  final String column;
  final Object? currentValue;
  final DbLensTheme? theme;

  /// Implementasi default [DbLensCellEditorBuilder] — lempar
  /// [DbLensCellEditCancelled] kalau pengguna menekan Cancel/menutup dialog.
  static Future<Object?> show(
    BuildContext context,
    String column,
    Object? currentValue,
  ) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => DbLensCellEditor(column: column, currentValue: currentValue),
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
  const _EditResult(this.value, {this.cancelled = false});
  final Object? value;
  final bool cancelled;
}

class _DbLensCellEditorState extends State<DbLensCellEditor> {
  late final TextEditingController _textController;
  late bool _boolValue;
  String? _validationError;

  bool get _isBool => widget.currentValue is bool;
  bool get _isInt => widget.currentValue is int;
  bool get _isDouble => widget.currentValue is double;
  bool get _isNum => widget.currentValue is num && !_isBool;

  @override
  void initState() {
    super.initState();
    _boolValue = widget.currentValue is bool ? widget.currentValue! as bool : false;
    _textController = TextEditingController(text: widget.currentValue?.toString() ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Object? _parseAndValidate() {
    if (_isBool) return _boolValue;

    final raw = _textController.text.trim();

    if (_isInt) {
      final parsed = int.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Harus berupa bilangan bulat (integer).');
        return null;
      }
      return parsed;
    }

    if (_isDouble) {
      final parsed = double.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Harus berupa angka desimal.');
        return null;
      }
      return parsed;
    }

    if (_isNum) {
      final parsed = num.tryParse(raw);
      if (parsed == null) {
        setState(() => _validationError = 'Harus berupa angka.');
        return null;
      }
      return parsed;
    }

    if (widget.currentValue == null && raw.toLowerCase() == 'null') return null;
    return raw;
  }

  void _save() {
    setState(() => _validationError = null);
    final value = _parseAndValidate();
    if (_validationError != null) return;
    Navigator.pop(context, _EditResult(value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? DbLensThemeScope.of(context);
    final value = widget.currentValue;

    return AlertDialog(
      title: Text('Edit ${widget.column}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isBool)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Value'),
              value: _boolValue,
              onChanged: (v) => setState(() => _boolValue = v),
            )
          else
            TextField(
              controller: _textController,
              autofocus: true,
              onChanged: (_) {
                if (_validationError != null) setState(() => _validationError = null);
              },
              keyboardType: value is num
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: 'New value',
                border: theme.outlineBorder(),
                errorText: _validationError,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const _EditResult(null, cancelled: true)),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
