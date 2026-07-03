import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Tampilan error standar dengan tombol "Coba lagi" opsional.
class DbLensErrorView extends StatelessWidget {
  const DbLensErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.theme,
  });

  final String message;
  final VoidCallback? onRetry;
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
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSecondary, fontSize: 13, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: t.accent),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
