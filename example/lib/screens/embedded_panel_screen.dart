import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';

/// Contoh menempel [DbLens.buildPanel] langsung di body Scaffold — tanpa
/// bottom sheet atau route baru. Cocok untuk taruh inspector di tab
/// debug/QA milik aplikasi sendiri.
class EmbeddedPanelScreen extends StatelessWidget {
  const EmbeddedPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Embedded Panel (buildPanel)')),
      body: DbLens.buildPanel(
        theme: DbLensThemeData.fromMaterialTheme(Theme.of(context)),
      ),
    );
  }
}
