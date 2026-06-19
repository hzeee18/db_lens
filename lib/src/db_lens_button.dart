import 'package:flutter/material.dart';
import 'db_lens.dart';

/// A ready-made button that opens the DbLens panel when tapped.
/// Drop it anywhere in your app — drawer, settings page, debug menu, etc.
///
/// Usage:
/// ```dart
/// DbLensButton()
///
/// // Custom style
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
  });

  /// Button label text.
  final String label;

  /// Button icon.
  final IconData icon;

  /// Optional custom button style.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => DbLens.open(context),
      icon: Icon(icon),
      label: Text(label),
      style: style,
    );
  }
}
