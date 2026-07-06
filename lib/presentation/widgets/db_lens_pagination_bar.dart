import 'package:flutter/material.dart';

import '../theme/db_lens_theme.dart';

/// Bar navigasi halaman — Prev/Next, "Page X of Y", tap untuk jump ke
/// halaman tertentu ([onJumpToPage]).
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
    this.theme,
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
  final DbLensTheme? theme;

  Future<void> _showJumpDialog(BuildContext context, DbLensTheme t) async {
    if (onJumpToPage == null) return;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _JumpToPageDialog(
        currentPage: page,
        totalPages: totalPages,
        theme: t,
      ),
    );

    if (!context.mounted || result == null || result == page) return;
    await onJumpToPage!(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = theme ?? DbLensThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PaginationButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              enabled: canGoPrevious && !isLoading,
              onPressed: canGoPrevious && !isLoading ? onPrevious : null,
              theme: t,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onJumpToPage != null && !isLoading
                    ? () => _showJumpDialog(context, t)
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
                      )
                    else
                      Text(
                        'Page ${page + 1} of $totalPages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: onJumpToPage != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: t.textMuted,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      totalRows == 0 ? 'No rows' : 'Rows $rangeStart–$rangeEnd of $totalRows',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _PaginationButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              enabled: canGoNext && !isLoading,
              onPressed: canGoNext && !isLoading ? onNext : null,
              theme: t,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
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
                  Icon(icon, size: 18, color: enabled ? theme.textPrimary : theme.textMuted),
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
                  Icon(icon, size: 18, color: enabled ? theme.textPrimary : theme.textMuted),
                ],
              ],
            ),
          ),
        ),
      ),
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
    if (value == null || value < 1 || value > widget.totalPages) return;
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Go')),
      ],
    );
  }
}
