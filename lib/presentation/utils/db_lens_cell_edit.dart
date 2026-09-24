import 'package:flutter/material.dart';

import '../../core/enums/source_type.dart';
import '../controllers/db_lens_controller.dart';
import '../hooks/db_lens_cell_editor_builder.dart';
import '../scope/db_lens_controller_scope.dart';
import '../theme/db_lens_theme.dart';
import '../widgets/db_lens_cell_editor.dart';
import 'db_lens_snackbar.dart';

/// Default cell-edit flow: dialog + save via callback or [DbLensControllerScope].
abstract final class DbLensCellEdit {
  /// Prompts for a new value, then saves via [onSave] or nearest controller.
  static Future<void> run(
    BuildContext context, {
    required String column,
    required Object? currentValue,
    required Map<String, Object?> row,
    Future<bool> Function(String column, Object? newValue, Map<String, Object?> row)? onSave,
    DbLensController? controller,
    bool? isSQLite,
    String successMessage = 'Cell updated',
    String failureMessage = 'Update failed',
  }) async {
    final sqlite = isSQLite ?? _inferIsSQLite(context, controller);
    final theme = DbLensThemeScope.of(context);

    Object? newValue;
    try {
      newValue = await DbLensCellEditor.show(
        context,
        column,
        currentValue,
        isSQLite: sqlite,
        theme: theme,
      );
    } on DbLensCellEditCancelled {
      return;
    }

    if (!context.mounted) return;

    if (onSave != null) {
      final ok = await onSave(column, newValue, row);
      if (context.mounted) {
        showDbLensSnack(context, ok ? successMessage : failureMessage, isError: !ok);
      }
      return;
    }

    final c = controller ?? DbLensControllerScope.maybeOf(context);
    if (c == null) return;

    final ok = await c.updateCellValue(column: column, newValue: newValue, row: row);
    if (context.mounted && ok) {
      showDbLensSnack(context, successMessage);
    } else if (context.mounted) {
      showDbLensSnack(context, failureMessage, isError: true);
    }
  }

  static bool _inferIsSQLite(BuildContext context, DbLensController? controller) {
    final c = controller ?? DbLensControllerScope.maybeOf(context);
    return c?.source.selectedSourceType != SourceType.sharedPreferences;
  }
}
