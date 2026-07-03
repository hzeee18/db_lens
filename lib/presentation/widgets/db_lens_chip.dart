import 'package:flutter/material.dart';

/// Badge/label kecil reusable — teks saja atau icon + teks, opsional onTap.
class DbLensChip extends StatelessWidget {
  const DbLensChip({
    super.key,
    this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    this.borderColor,
    this.borderRadius = 10,
    this.onTap,
    this.expandWidth = false,
  });

  final IconData? icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool expandWidth;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: expandWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        mainAxisSize: expandWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 11, color: foreground),
          if (icon != null) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: chip);
    }
    return chip;
  }
}
