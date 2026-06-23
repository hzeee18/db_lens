import 'package:flutter/material.dart';

import '../../core/models/db_lens_config.dart';
import '../../db_lens_facade.dart';

/// A ready-made button that opens the DbLens panel when tapped.
///
/// Usage:
/// ```dart
/// DbLensButton()
///
/// DbLensButton(
///   label: 'Inspect Database',
///   icon: Icons.storage,
/// )
/// ```
class DbLensButton extends StatelessWidget {
  const DbLensButton({
    super.key,
    this.label = 'DB Lens',
    this.icon = Icons.storage,
    this.style,
    this.config,
  });

  final String label;
  final IconData icon;
  final ButtonStyle? style;
  final DbLensConfig? config;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => DbLens.open(context, config: config),
      icon: Icon(icon),
      label: Text(label),
      style: style,
    );
  }
}
