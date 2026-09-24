import 'package:flutter/material.dart';

import '../../core/models/db_lens_config.dart';
import '../../db_lens_facade.dart';
import '../controllers/db_lens_controller.dart';
import '../theme/db_lens_theme.dart';
import '../theme/db_lens_theme_data.dart';

/// Menyediakan [DbLensController] (dan tema) ke seluruh subtree widget.
///
/// Ini satu-satunya cara menyusun UI custom di atas `db_lens` — widget
/// reusable seperti [DbLensSourceList]/[DbLensToolbar] mengambil controller
/// lewat [DbLensControllerScope.of], bukan lewat parameter constructor,
/// supaya bisa dikomposisi bebas tanpa prop-drilling:
///
/// ```dart
/// DbLensControllerScope(
///   controller: DbLens.createController(),
///   child: DbLensLayout(
///     sidebar: DbLensSourceList(),
///     body: DbLensTableView(rows: ..., columns: ...),
///   ),
/// )
/// ```
///
/// Kalau [controller] tidak diisi, scope membuat dan mengelola lifecycle-nya
/// sendiri (initialize saat mount, dispose saat unmount). Kalau diisi,
/// caller bertanggung jawab memanggil [DbLensController.initialize] sebelum
/// widget dipasang dan men-dispose-nya sendiri.
class DbLensControllerScope extends StatefulWidget {
  const DbLensControllerScope({
    super.key,
    required this.child,
    this.controller,
    this.config = const DbLensConfig(),
    this.theme,
  });

  final Widget child;
  final DbLensController? controller;
  final DbLensConfig config;
  final DbLensThemeData? theme;

  /// Ambil [DbLensController] dari scope terdekat di atas [context].
  static DbLensController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_DbLensControllerInherited>();
    assert(
      scope != null,
      'DbLensControllerScope.of() dipanggil tanpa ada DbLensControllerScope '
      'di atasnya. Bungkus widget tree dengan DbLensControllerScope(...) '
      'dulu.',
    );
    return scope!.controller;
  }

  /// Returns null when no [DbLensControllerScope] ancestor exists.
  static DbLensController? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_DbLensControllerInherited>()
        ?.controller;
  }

  @override
  State<DbLensControllerScope> createState() => _DbLensControllerScopeState();
}

class _DbLensControllerScopeState extends State<DbLensControllerScope> {
  late final DbLensController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? DbLens.createController(config: widget.config);
    if (_ownsController) {
      _controller.initialize();
    } else {
      assert(
        _controller.isInitialized,
        'Controller passed to DbLensControllerScope must be initialized '
        'before mounting. Call controller.initialize() first.',
      );
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
    // Release gating ada di DbLens.open / buildPanel / DbLensButton
    // (lihat DbLensConfig.allowInRelease), bukan di scope.
    // Sengaja TIDAK dibungkus AnimatedBuilder/ListenableBuilder di sini —
    // scope cuma menyediakan controller, tidak ikut menentukan kapan
    // subtree rebuild. Widget daun (DbLensSourceList, dst.) yang
    // memutuskan sendiri lewat AnimatedBuilder ke sub-controller yang
    // relevan, supaya rebuild tetap granular (mengetik di search box tidak
    // membangunkan ulang widget yang tidak terkait).
    return DbLensThemeScope(
      theme: DbLensTheme(widget.theme),
      child: _DbLensControllerInherited(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}

class _DbLensControllerInherited extends InheritedWidget {
  const _DbLensControllerInherited({
    required this.controller,
    required super.child,
  });

  final DbLensController controller;

  @override
  bool updateShouldNotify(_DbLensControllerInherited oldWidget) =>
      controller != oldWidget.controller;
}
