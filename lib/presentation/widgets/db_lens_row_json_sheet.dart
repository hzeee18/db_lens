import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/db_lens_theme.dart';
import '../utils/json_view_utils.dart';
import 'db_lens_json_view.dart';

/// Bottom sheet untuk inspeksi baris sebagai JSON dengan syntax highlighting.
class DbLensRowJsonSheet extends StatefulWidget {
  const DbLensRowJsonSheet({
    super.key,
    required this.row,
    required this.theme,
    this.rowNum,
    this.canEdit = false,
    this.onCopied,
    this.onSave,
    this.onSaved,
  });

  final Map<String, Object?> row;
  final DbLensTheme theme;
  final int? rowNum;
  final bool canEdit;
  final VoidCallback? onCopied;
  final Future<String?> Function(Map<String, Object?> updatedRow)? onSave;
  final VoidCallback? onSaved;

  static Future<void> show(
    BuildContext context, {
    required Map<String, Object?> row,
    required DbLensTheme theme,
    int? rowNum,
    bool canEdit = false,
    VoidCallback? onCopied,
    Future<String?> Function(Map<String, Object?> updatedRow)? onSave,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: DbLensRowJsonSheet(
          row: row,
          theme: theme,
          rowNum: rowNum,
          canEdit: canEdit,
          onCopied: onCopied,
          onSave: onSave,
          onSaved: onSaved,
        ),
      ),
    );
  }

  @override
  State<DbLensRowJsonSheet> createState() => _DbLensRowJsonSheetState();
}

class _DbLensRowJsonSheetState extends State<DbLensRowJsonSheet> {
  late final TextEditingController _editController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _inlineError;
  String? _parseError;
  bool _isJsonValid = true;

  String get _viewJsonText => DbLensJsonUtils.encodePretty(widget.row);

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: _viewJsonText);
    _editController.addListener(_validateEditedJson);
  }

  @override
  void dispose() {
    _editController.removeListener(_validateEditedJson);
    _editController.dispose();
    super.dispose();
  }

  void _validateEditedJson() {
    final text = _editController.text;
    setState(() {
      try {
        DbLensJsonUtils.parseRowJson(text);
        _parseError = null;
        _isJsonValid = true;
        if (_inlineError != null && _inlineError!.startsWith('Invalid JSON')) {
          _inlineError = null;
        }
      } catch (error) {
        _parseError =
            error is FormatException ? error.message : 'Invalid JSON: $error';
        _isJsonValid = false;
      }
    });
  }

  void _enterEditMode() {
    _editController.text = _viewJsonText;
    setState(() {
      _isEditing = true;
      _inlineError = null;
      _parseError = null;
      _isJsonValid = true;
    });
  }

  void _cancelEdit() {
    _editController.text = _viewJsonText;
    setState(() {
      _isEditing = false;
      _inlineError = null;
      _parseError = null;
      _isJsonValid = true;
    });
  }

  Future<void> _saveEdit() async {
    if (!_isJsonValid || widget.onSave == null) return;

    late final Map<String, Object?> parsed;
    try {
      parsed = DbLensJsonUtils.parseRowJson(_editController.text);
    } catch (error) {
      setState(() {
        _inlineError = error is FormatException
            ? 'Invalid JSON: ${error.message}'
            : 'Invalid JSON: $error';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    final error = await widget.onSave!(parsed);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSaving = false;
        _inlineError = error;
      });
      return;
    }

    widget.onSaved?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final lineCount = _editController.text.split('\n').length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.theme.bg,
        borderRadius: const BorderRadius.vertical(top: DbLensTheme.sheetRadius),
        border: Border(
          top: BorderSide(color: widget.theme.border),
          left: BorderSide(color: widget.theme.border),
          right: BorderSide(color: widget.theme.border),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHandle(),
            _buildHeader(context),
            const Divider(height: 1),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    _isEditing ? _buildEditBody(lineCount) : _buildViewBody(),
              ),
            ),
            if (_inlineError != null) _buildErrorBanner(),
            const Divider(height: 1),
            _isEditing ? _buildEditActions(context) : _buildCopyButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 32,
        height: 3,
        decoration: BoxDecoration(
          color: widget.theme.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = widget.rowNum != null ? 'Row #${widget.rowNum}' : 'Row JSON';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        children: [
          Icon(Icons.data_object_outlined,
              size: 18, color: widget.theme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEditing ? '$title · Edit' : title,
              style: TextStyle(
                color: widget.theme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.canEdit && widget.onSave != null && !_isEditing)
            IconButton(
              tooltip: 'Edit',
              onPressed: _enterEditMode,
              icon: Icon(Icons.edit_outlined,
                  size: 20, color: widget.theme.accent),
            ),
          IconButton(
            tooltip: 'Close',
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close, size: 20, color: widget.theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildViewBody() {
    return SingleChildScrollView(
      key: const ValueKey('view'),
      padding: const EdgeInsets.all(16),
      child: DbLensJsonSyntaxText(
        json: _viewJsonText,
        theme: widget.theme,
      ),
    );
  }

  Widget _buildEditBody(int lineCount) {
    return Padding(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: _editController,
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.5,
                color: widget.theme.syntaxDefault,
              ),
              decoration: widget.theme
                  .fieldDecoration(
                    hintText: '{ ... }',
                    fillColor: widget.theme.bg,
                  )
                  .copyWith(
                    contentPadding: const EdgeInsets.all(12),
                    errorText: _parseError,
                    errorStyle: TextStyle(color: Colors.redAccent.shade200),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$lineCount lines · ${_editController.text.length} chars',
            style: TextStyle(
              color: widget.theme.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _inlineError!,
                style: TextStyle(
                  color: widget.theme.textPrimary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: FilledButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: _viewJsonText));
          widget.onCopied?.call();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.content_copy, size: 18),
        label: const Text('Copy'),
      ),
    );
  }

  Widget _buildEditActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : _cancelEdit,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isSaving || !_isJsonValid ? null : _saveEdit,
              child: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.theme.bg,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
