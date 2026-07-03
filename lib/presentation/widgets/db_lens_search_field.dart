import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Search bar reusable dengan prefix icon, clear button, dan border 3 state.
class DbLensSearchField extends StatelessWidget {
  const DbLensSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 8),
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = DbLensThemeScope.of(context);

    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: theme.fieldDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: showClear
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                  icon: const Icon(Icons.close, size: 18),
                )
              : null,
        ),
      ),
    );
  }
}
