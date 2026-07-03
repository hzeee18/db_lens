import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/models/db_lens_config.dart';
import '../../db_lens_facade.dart';
import '../controllers/db_lens_controller.dart';
import '../theme/db_lens_theme.dart';
import '../theme/db_lens_theme_data.dart';

/// Mengurus lifecycle [DbLensController] untuk custom UI yang di-embed
/// langsung di widget tree konsumen (bukan lewat Navigator.push).
///
/// Berbeda dari [DbLensCustomHost] (dipakai internal oleh
/// [DbLens.openCustom]) — widget ini untuk dipakai langsung oleh konsumen
/// yang mau menaruh inspector di dalam scaffold/tab mereka sendiri, tanpa
/// route baru.
class DbLensInspectorScope extends StatefulWidget {
  const DbLensInspectorScope({
    super.key,
    required this.builder,
    this.config = const DbLensConfig(),
    this.theme,
    this.controller,
  });

  final Widget Function(BuildContext context, DbLensController controller)
      builder;
  final DbLensConfig config;
  final DbLensThemeData? theme;

  /// Jika diisi, scope memakai controller ini dan TIDAK men-dispose-nya.
  final DbLensController? controller;

  @override
  State<DbLensInspectorScope> createState() => _DbLensInspectorScopeState();
}

class _DbLensInspectorScopeState extends State<DbLensInspectorScope> {
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
    if (kReleaseMode) return const SizedBox.shrink();
    return DbLensThemeScope(
      theme: DbLensTheme(widget.theme),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(context, _controller),
      ),
    );
  }
}
