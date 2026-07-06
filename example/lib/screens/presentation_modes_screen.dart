import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';

/// Demo [DbLensConfig.presentationMode] — menentukan tampilan default
/// [DbLens.open].
class PresentationModesScreen extends StatelessWidget {
  const PresentationModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentation Modes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DbLensConfig.presentationMode menentukan tampilan '
              'DbLens.open() — bottomSheet (default) atau fullPage.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => DbLens.open(
                context,
                config: const DbLensConfig(
                  presentationMode: DbLensPresentationMode.bottomSheet,
                ),
              ),
              child: const Text('presentationMode = bottomSheet'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => DbLens.open(
                context,
                config: const DbLensConfig(
                  presentationMode: DbLensPresentationMode.fullPage,
                ),
              ),
              child: const Text('presentationMode = fullPage'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Untuk menempel panel langsung di widget tree tanpa navigasi, '
              'pakai DbLens.buildPanel() — lihat demo "Embedded Panel".',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
