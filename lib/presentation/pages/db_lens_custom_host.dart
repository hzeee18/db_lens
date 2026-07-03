import 'package:flutter/material.dart';

import '../../core/models/db_lens_config.dart';
import '../../db_lens_facade.dart';
import '../controllers/db_lens_controller.dart';
import '../theme/db_lens_theme.dart';
import '../theme/db_lens_theme_data.dart';

/// Host internal untuk DbLens.openCustom — mengurus lifecycle
/// [DbLensController] (create + initialize + dispose) di sekitar builder
/// custom milik konsumen.
class DbLensCustomHost extends StatefulWidget {
  const DbLensCustomHost({
    super.key,
    required this.builder,
    required this.config,
    this.theme,
    this.controller,
  });

  final Widget Function(BuildContext context, DbLensController controller)
      builder;
  final DbLensConfig config;
  final DbLensThemeData? theme;

  /// Jika diisi, host memakai controller ini dan TIDAK men-dispose-nya.
  final DbLensController? controller;

  @override
  State<DbLensCustomHost> createState() => _DbLensCustomHostState();
}

class _DbLensCustomHostState extends State<DbLensCustomHost> {
  late final DbLensController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        DbLens.createController(config: widget.config);
    if (_ownsController) {
      _controller.initialize();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DbLensThemeScope(
      theme: DbLensTheme(widget.theme),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(context, _controller),
      ),
    );
  }
}
