import 'package:flutter/widgets.dart';

/// Primitive komposisi slot-based — susun panel database inspector dari
/// widget mana pun, bukan lewat flag boolean di satu widget besar.
///
/// ```dart
/// DbLensLayout(
///   sidebar: DbLensSourceList(),
///   toolbar: DbLensToolbar(),
///   body: DbLensTableView(rows: rows, columns: columns),
/// )
/// ```
///
/// Murni layout — tidak tahu apa itu `db_lens`, tidak depend controller
/// apa pun. Bisa dipakai untuk susunan apa pun.
class DbLensLayout extends StatelessWidget {
  const DbLensLayout({
    super.key,
    required this.body,
    this.header,
    this.sidebar,
    this.toolbar,
    this.bottomBar,
    this.sidebarWidth = 250,
  });

  final Widget? header;
  final Widget? sidebar;
  final Widget? toolbar;
  final Widget body;
  final Widget? bottomBar;
  final double sidebarWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        if (toolbar != null) toolbar!,
        Expanded(
          child: sidebar == null
              ? body
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: sidebarWidth, child: sidebar),
                    Expanded(child: body),
                  ],
                ),
        ),
        if (bottomBar != null) bottomBar!,
      ],
    );
  }
}
