import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Baris hint + status ringkas (mis. "Tap row to view JSON" · "12–20 of 340").
/// Murni presentational — teks disiapkan oleh pemanggil.
class DbLensStatusBar extends StatelessWidget {
  const DbLensStatusBar({super.key, required this.hintText, required this.statusText});

  final String hintText;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);
    return Row(
      children: [
        Icon(Icons.info_outline, size: 13, color: theme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(hintText, style: TextStyle(color: theme.textMuted, fontSize: 11)),
        ),
        Text(statusText, style: TextStyle(color: theme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
