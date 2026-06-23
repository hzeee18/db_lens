import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:db_lens/db_lens.dart';

import 'seed/shared_preferences_seeder.dart';
import 'seed/sqlite_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    _initDatabase(),
    _initSharedPreferences(),
  ]);
  runApp(const MyApp());
}

Future<void> _initDatabase() async {
  final db = await SqliteSeeder.open();
  DbLens.register('Example DB', db);
}

Future<void> _initSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await SharedPreferencesSeeder.seed(prefs);
  DbLens.registerSharedPreferences('App Prefs', prefs);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DbLens Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DbLens Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'Open DB Lens',
            onPressed: () => DbLens.open(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Debug Menu',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Inspect Data Sources'),
              subtitle: const Text('SQLite tables & SharedPreferences'),
              trailing: const DbLensButton(),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storage, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              'db_lens example',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the drawer or tap the icon\nin the app bar to inspect SQLite & prefs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),    
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Or use DbLensButton directly:',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const DbLensButton(),
            const SizedBox(height: 8),
            DbLensButton(
              label: 'Custom Label',
              icon: Icons.bug_report,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}