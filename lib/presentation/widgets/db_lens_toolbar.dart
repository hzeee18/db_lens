import 'package:flutter/material.dart';

import '../controllers/db_lens_controller.dart';
import '../scope/db_lens_controller_scope.dart';
import '../theme/db_lens_theme.dart';

/// Toolbar slot-based — [status] di kiri, [actions] di kanan.
///
/// Composition over configuration: alih-alih flag `showCopy`/`showRefresh`,
/// tempel widget aksi yang diinginkan (mis. [DbLensRefreshAction],
/// [DbLensCopyJsonAction], atau aksi kustom milik konsumen).
class DbLensToolbar extends StatelessWidget {
  const DbLensToolbar({
    super.key,
    this.status,
    this.actions = const [],
  });

  final Widget? status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          if (status != null) Expanded(child: status!),
          for (final action in actions) ...[action, const SizedBox(width: 4)],
        ],
      ),
    );
  }
}

/// Tombol refresh bawaan — memanggil [DbLensController.refresh].
class DbLensRefreshAction extends StatelessWidget {
  const DbLensRefreshAction({super.key, this.controller});

  final DbLensController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller ?? DbLensControllerScope.of(context);
    final theme = DbLensThemeScope.of(context);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => IconButton(
        tooltip: 'Refresh',
        onPressed: c.canRefresh ? c.refresh : null,
        visualDensity: VisualDensity.compact,
        icon: c.table.refreshing || c.query.refreshing
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent),
              )
            : const Icon(Icons.refresh_rounded, size: 18),
      ),
    );
  }
}

/// Tombol "copy semua baris sebagai JSON" bawaan.
class DbLensCopyJsonAction extends StatelessWidget {
  const DbLensCopyJsonAction({super.key, this.controller, this.onCopied});

  final DbLensController? controller;
  final ValueChanged<String>? onCopied;

  @override
  Widget build(BuildContext context) {
    final c = controller ?? DbLensControllerScope.of(context);
    final theme = DbLensThemeScope.of(context);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => IconButton(
        tooltip: 'Copy all as JSON',
        onPressed: c.canCopyJson
            ? () async {
                final json = await c.copyAllAsJson();
                if (json != null) onCopied?.call(json);
              }
            : null,
        visualDensity: VisualDensity.compact,
        icon: c.copyingJson
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent),
              )
            : Icon(Icons.content_copy, size: 18, color: theme.accent),
      ),
    );
  }
}
