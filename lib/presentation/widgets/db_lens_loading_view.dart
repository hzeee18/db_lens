import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Indikator loading standar — spinner kecil + label "Loading…".
class DbLensLoadingView extends StatelessWidget {
  const DbLensLoadingView({super.key, this.theme, this.label = 'Loading…'});

  final DbLensTheme? theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = theme ?? DbLensThemeScope.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: t.accent, strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: t.textMuted.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
