import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:db_lens/db_lens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initDatabase();
  runApp(const MyApp());
}

Future<void> _initDatabase() async {
  final db = await openDatabase(
    join(await getDatabasesPath(), 'example.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          age INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          stock INTEGER DEFAULT 0
        )
      ''');

      // Seed some dummy data
      final batch = db.batch();
      for (var i = 1; i <= 20; i++) {
        batch.insert('users', {
          'name': 'User $i',
          'email': 'user$i@example.com',
          'age': 20 + i,
        });
      }
      for (var i = 1; i <= 10; i++) {
        batch.insert('products', {
          'name': 'Product $i',
          'price': i * 9.99,
          'stock': i * 5,
        });
      }
      await batch.commit();
    },
  );

  // Register the database with DbLens
  DbLens.register('Example DB', db);
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
          // Option 2: open manually from anywhere
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
              title: const Text('Inspect Database'),
              subtitle: const Text('View SQLite tables & data'),
              // Option 1: use DbLensButton
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
              'Open the drawer or tap the icon\nin the app bar to inspect the database.',
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
            // Option 1: drop DbLensButton anywhere
            const DbLensButton(),
            const SizedBox(height: 8),
            // Custom style
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
