import 'package:flutter/material.dart';

import '../controllers/db_lens_history_controller.dart';
import '../theme/db_lens_theme.dart';
import 'db_lens_history_panel.dart';

/// Wrapper tipis yang menampilkan [DbLensHistoryPanel] sebagai modal bottom
/// sheet. Untuk tampilan full-page/embed, pakai [DbLensHistoryPanel]
/// langsung di `Scaffold`/widget tree sendiri.
class DbLensHistorySheet extends StatelessWidget {
  const DbLensHistorySheet({
    super.key,
    required this.controller,
    required this.sourceName,
    this.theme,
  });

  final DbLensHistoryController controller;
  final String sourceName;
  final DbLensTheme? theme;

  static Future<void> show(
    BuildContext context, {
    required DbLensHistoryController controller,
    required String sourceName,
    DbLensTheme? theme,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DbLensHistorySheet(
        controller: controller,
        sourceName: sourceName,
        theme: theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = theme ?? DbLensThemeScope.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(top: DbLensTheme.sheetRadius),
        border: Border(
          top: BorderSide(color: t.border),
          left: BorderSide(color: t.border),
          right: BorderSide(color: t.border),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHandle(t),
            Flexible(
              child: DbLensHistoryPanel(controller: controller, sourceName: sourceName),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(DbLensTheme t) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 32,
        height: 3,
        decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}
