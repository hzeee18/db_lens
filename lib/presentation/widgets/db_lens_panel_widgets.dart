import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';
import 'db_lens_highlighted_text.dart';

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

class DbLensPaginationButton extends StatelessWidget {
  const DbLensPaginationButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final DbLensTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: enabled ? theme.bg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label == 'Prev') ...[
                  Icon(
                    icon,
                    size: 18,
                    color: enabled ? theme.textPrimary : theme.textMuted,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? theme.textPrimary : theme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (label == 'Next') ...[
                  const SizedBox(width: 4),
                  Icon(
                    icon,
                    size: 18,
                    color: enabled ? theme.textPrimary : theme.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DbLensPaginationBar extends StatelessWidget {
  const DbLensPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalRows,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.theme,
    this.onJumpToPage,
    this.isLoading = false,
  });

  final int page;
  final int totalPages;
  final int rangeStart;
  final int rangeEnd;
  final int totalRows;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Future<void> Function(int page)? onJumpToPage;
  final bool isLoading;
  final DbLensTheme theme;

  Future<void> _showJumpDialog(BuildContext context) async {
    if (onJumpToPage == null) return;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _JumpToPageDialog(
        currentPage: page,
        totalPages: totalPages,
        theme: theme,
      ),
    );

    if (!context.mounted || result == null || result == page) return;
    await onJumpToPage!(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DbLensPaginationButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              enabled: canGoPrevious && !isLoading,
              onPressed: canGoPrevious && !isLoading ? onPrevious : null,
              theme: theme,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onJumpToPage != null && !isLoading
                    ? () => _showJumpDialog(context)
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.accent,
                        ),
                      )
                    else
                      Text(
                        'Page ${page + 1} of $totalPages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: onJumpToPage != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: theme.textMuted,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      totalRows == 0
                          ? 'No rows'
                          : 'Rows $rangeStart–$rangeEnd of $totalRows',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DbLensPaginationButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              enabled: canGoNext && !isLoading,
              onPressed: canGoNext && !isLoading ? onNext : null,
              theme: theme,
            ),
          ],
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

class DbLensLoadingIndicator extends StatelessWidget {
  const DbLensLoadingIndicator({super.key, required this.theme});

  final DbLensTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: theme.accent,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading…',
            style: TextStyle(
              color: theme.textMuted.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class DbLensEmptyPlaceholder extends StatelessWidget {
  const DbLensEmptyPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DbLensTheme theme;

  @override
  Widget build(BuildContext context) {
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
                color: theme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Icon(icon, color: theme.textMuted, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

class _JumpToPageDialog extends StatefulWidget {
  const _JumpToPageDialog({
    required this.currentPage,
    required this.totalPages,
    required this.theme,
  });

  final int currentPage;
  final int totalPages;
  final DbLensTheme theme;

  @override
  State<_JumpToPageDialog> createState() => _JumpToPageDialogState();
}

class _JumpToPageDialogState extends State<_JumpToPageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentPage + 1}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 || value > widget.totalPages) {
      return;
    }
    Navigator.pop(context, value - 1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jump to page'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: '1 – ${widget.totalPages}',
          border: widget.theme.outlineBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Go'),
        ),
      ],
    );
  }
}
