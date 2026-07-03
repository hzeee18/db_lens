import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Placeholder untuk state kosong (belum ada data/hasil).
class DbLensEmptyState extends StatelessWidget {
  const DbLensEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DbLensTheme? theme;

  @override
  Widget build(BuildContext context) {
    final t = theme ?? DbLensThemeScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: Icon(icon, color: t.textMuted, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
