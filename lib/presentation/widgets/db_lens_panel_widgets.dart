import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';
import 'db_lens_highlighted_text.dart';

/// Widget chrome internal untuk [DbLensPanel] (drag handle, selector chip,
/// skeleton loading). Bukan bagian dari widget library publik — untuk
/// komponen reusable lihat db_lens_source_list.dart, db_lens_toolbar.dart,
/// dst.
class DbLensUnfocusTap extends StatelessWidget {
  const DbLensUnfocusTap({
    super.key,
    required this.onTapOutside,
    required this.child,
  });

  final VoidCallback onTapOutside;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTapOutside,
      child: child,
    );
  }
}

class DbLensDragHandleBar extends StatefulWidget {
  const DbLensDragHandleBar({
    super.key,
    required this.controller,
    required this.minSize,
    required this.maxSize,
    required this.dismissThreshold,
    required this.onDismiss,
    required this.theme,
  });

  final DraggableScrollableController controller;
  final double minSize;
  final double maxSize;
  final double dismissThreshold;
  final Future<void> Function() onDismiss;
  final DbLensTheme theme;

  @override
  State<DbLensDragHandleBar> createState() => _DbLensDragHandleBarState();
}

class _DbLensDragHandleBarState extends State<DbLensDragHandleBar> {
  static const _handleIdle = Color(0xFFD1D5DB);

  bool _dragging = false;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.controller.isAttached) return;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final delta = -details.delta.dy / screenHeight;
    final newSize =
        (widget.controller.size + delta).clamp(widget.minSize, widget.maxSize);
    widget.controller.jumpTo(newSize);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _dragging = false);
    if (widget.controller.isAttached &&
        widget.controller.size < widget.dismissThreshold) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => setState(() => _dragging = true),
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      onVerticalDragCancel: () => setState(() => _dragging = false),
      child: SizedBox(
        height: 28,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: _dragging ? 40 : 32,
            height: _dragging ? 4 : 3,
            decoration: BoxDecoration(
              color: _dragging ? widget.theme.accent : _handleIdle,
              borderRadius: BorderRadius.circular(2),
              boxShadow: _dragging
                  ? [
                      BoxShadow(
                        color: widget.theme.accent.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class DbLensSelectorChip extends StatelessWidget {
  const DbLensSelectorChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    this.highlight = '',
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final DbLensTheme theme;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? theme.accent : theme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: DbLensHighlightedText(
            text: label,
            highlight: highlight,
            theme: theme,
            style: TextStyle(
              color: isSelected ? theme.accent : theme.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'monospace',
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class DbLensTablePageSkeleton extends StatelessWidget {
  const DbLensTablePageSkeleton({
    super.key,
    required this.theme,
    this.rowCount = 8,
    this.columnCount = 4,
  });

  final DbLensTheme theme;
  final int rowCount;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.bg.withValues(alpha: 0.72),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: rowCount,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) {
          return Row(
            children: List.generate(columnCount, (index) {
              return Expanded(
                flex: index == 0 ? 1 : 2,
                child: Container(
                  height: 14,
                  margin: EdgeInsets.only(right: index < columnCount - 1 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: theme.border.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class DbLensSelectorField extends StatefulWidget {
  const DbLensSelectorField({
    super.key,
    required this.icon,
    required this.label,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.theme,
    this.searchText = '',
    this.onSearchChanged,
    this.searchHint = 'Search…',
  });

  final IconData icon;
  final String label;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;
  final DbLensTheme theme;
  final String searchText;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  @override
  State<DbLensSelectorField> createState() => _DbLensSelectorFieldState();
}

class _DbLensSelectorFieldState extends State<DbLensSelectorField> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchText);
  }

  @override
  void didUpdateWidget(DbLensSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != _searchController.text) {
      _searchController.text = widget.searchText;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Icon(widget.icon, size: 12, color: widget.theme.textMuted),
              const SizedBox(width: 5),
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: widget.theme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        if (widget.onSearchChanged != null) ...[
          TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: widget.theme.fieldDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search, size: 16),
              suffixIcon: widget.searchText.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged?.call('');
                      },
                      icon: const Icon(Icons.close, size: 16),
                    ),
            ).copyWith(contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            )),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: widget.theme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.theme.border),
          ),
          child: widget.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.searchText.isEmpty
                        ? 'No items'
                        : 'No matches for "${widget.searchText}"',
                    style: TextStyle(
                      color: widget.theme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: widget.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: DbLensSelectorChip(
                          label: item,
                          isSelected: item == widget.selected,
                          onTap: () => widget.onSelected(item),
                          theme: widget.theme,
                          highlight: widget.searchText,
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
