import 'package:flutter/material.dart';

import '../controllers/db_lens_history_controller.dart';
import '../theme/db_lens_theme.dart';

/// History header — back, title, search/filter toggles, tracking, clear.
///
/// Compose separately from [DbLensHistoryPanel] for sheets or full-page routes.
class DbLensHistoryHeader extends StatelessWidget {
  const DbLensHistoryHeader({
    super.key,
    required this.controller,
    this.sourceName,
    this.title = 'Change History',
    this.onBack,
    this.showSearchToggle = true,
    this.showFilterToggle = true,
    this.theme,
  });

  final DbLensHistoryController controller;
  final String? sourceName;
  final String title;
  final VoidCallback? onBack;
  final bool showSearchToggle;
  final bool showFilterToggle;
  final DbLensTheme? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? DbLensThemeScope.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final hasData = !c.isEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 12),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back, size: 20, color: theme.textPrimary),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.history, size: 18, color: theme.accent),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sourceName != null)
                      Text(
                        sourceName!,
                        style: TextStyle(color: theme.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (hasData && showSearchToggle)
                _HeaderIconButton(
                  tooltip: c.searchExpanded ? 'Hide search' : 'Search',
                  icon: Icons.search,
                  active: c.searchExpanded || c.hasActiveSearch,
                  theme: theme,
                  onPressed: c.toggleSearchExpanded,
                ),
              if (hasData && showFilterToggle)
                _HeaderIconButton(
                  tooltip: c.filtersExpanded ? 'Hide filters' : 'Filter',
                  icon: Icons.filter_list,
                  active: c.filtersExpanded || c.hasActiveChangeTypeFilters || c.hasActiveTableFilter,
                  theme: theme,
                  onPressed: c.toggleFiltersExpanded,
                ),
              if (c.canToggleTracking) _TrackingToggle(controller: c, theme: theme),
              if (hasData)
                TextButton(
                  onPressed: () => _confirmClear(context, c),
                  child: const Text('Clear'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, DbLensHistoryController c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Clear all change history for this source?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await c.clear();
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.theme,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final DbLensTheme theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 20,
        color: active ? theme.accent : theme.textMuted,
      ),
      style: IconButton.styleFrom(
        backgroundColor: active ? theme.accent.withValues(alpha: 0.12) : null,
      ),
    );
  }
}

class _TrackingToggle extends StatelessWidget {
  const _TrackingToggle({required this.controller, required this.theme});

  final DbLensHistoryController controller;
  final DbLensTheme theme;

  @override
  Widget build(BuildContext context) {
    final enabled = controller.trackingEnabled;
    return Tooltip(
      message: enabled ? 'Pause tracking' : 'Resume tracking',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Track', style: TextStyle(color: theme.textMuted, fontSize: 11)),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: enabled,
              activeThumbColor: theme.accent,
              onChanged: controller.setTrackingEnabled,
            ),
          ),
        ],
      ),
    );
  }
}
