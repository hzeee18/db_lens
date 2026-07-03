import 'package:db_lens/db_lens.dart';
import 'package:flutter/material.dart';

/// Demo [DbLensConfig.presentationMode] dan shorthand `mode:` di
/// [DbLens.open]. `mode:` selalu mengalahkan `config.presentationMode`
/// jika keduanya diisi.
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
              'DbLensConfig.presentationMode menentukan tampilan default '
              'DbLens.open(). Parameter mode: adalah shorthand override yang '
              'mengalahkan config.presentationMode.',
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
              child: const Text('config.presentationMode = bottomSheet'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => DbLens.open(
                context,
                config: const DbLensConfig(
                  presentationMode: DbLensPresentationMode.fullPage,
                ),
              ),
              child: const Text('config.presentationMode = fullPage'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => DbLens.open(
                context,
                config: const DbLensConfig(
                  presentationMode: DbLensPresentationMode.bottomSheet,
                ),
                mode: DbLensPresentationMode.fullPage,
              ),
              child: const Text('mode: fullPage (override config)'),
            ),
            const SizedBox(height: 24),
            const Text(
              'embedded tidak bisa dipakai lewat DbLens.open() — lihat demo '
              '"Embedded Panel (buildPanel)" di menu utama.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
