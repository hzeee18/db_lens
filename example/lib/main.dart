import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:db_lens/db_lens.dart';

import 'screens/custom_ui_screen.dart';
import 'screens/embedded_panel_screen.dart';
import 'screens/history_demo_screen.dart';
import 'screens/presentation_modes_screen.dart';
import 'seed/shared_preferences_seeder.dart';
import 'seed/sqlite_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await _initDatabase();
  await _initSharedPreferences();
  runApp(MyApp(database: db));
}

Future<Database> _initDatabase() async {
  final db = await SqliteSeeder.open();
  DbLens.register('Example DB', db);
  return db;
}

Future<void> _initSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await SharedPreferencesSeeder.seed(prefs);
  DbLens.registerSharedPreferences('App Prefs', prefs);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.database});

  final Database database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DbLens Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: HomeScreen(database: database),
    );
  }
}

class _DemoItem {
  const _DemoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context)? onTap;
  final WidgetBuilder? builder;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.database});

  final Database database;

  List<_DemoItem> _demos() => [
        _DemoItem(
          title: 'Bottom Sheet (default)',
          subtitle: 'DbLens.open(context) — default presentation mode',
          icon: Icons.vertical_align_bottom,
          onTap: (context) => DbLens.open(context),
        ),
        _DemoItem(
          title: 'Full Page',
          subtitle:
              'DbLens.open(context, config: DbLensConfig(presentationMode: fullPage))',
          icon: Icons.fullscreen,
          onTap: (context) => DbLens.open(
            context,
            config: const DbLensConfig(
              presentationMode: DbLensPresentationMode.fullPage,
            ),
          ),
        ),
        _DemoItem(
          title: 'Presentation Mode',
          subtitle: 'DbLensConfig.presentationMode',
          icon: Icons.tune,
          builder: (context) => const PresentationModesScreen(),
        ),
        _DemoItem(
          title: 'Embedded Panel (buildPanel)',
          subtitle: 'DbLens.buildPanel() ditempel langsung di body Scaffold',
          icon: Icons.dashboard_customize,
          builder: (context) => const EmbeddedPanelScreen(),
        ),
        _DemoItem(
          title: 'Custom UI (DbLensControllerScope)',
          subtitle:
              'Compose widget sendiri: DbLensControllerScope + DbLensLayout + widget publik',
          icon: Icons.widgets_outlined,
          builder: (context) => const CustomUiScreen(),
        ),
        _DemoItem(
          title: 'Change History',
          subtitle:
              'configureHistory · createHistoryController · DbLensHistoryPanel',
          icon: Icons.history,
          builder: (context) => HistoryDemoScreen(database: database),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final demos = _demos();
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
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Database Inspector Framework',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          for (final demo in demos)
            Card(
              child: ListTile(
                leading: Icon(demo.icon, color: Colors.deepPurple),
                title: Text(demo.title),
                subtitle: Text(demo.subtitle),
                onTap: () {
                  if (demo.onTap != null) {
                    demo.onTap!(context);
                  } else if (demo.builder != null) {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: demo.builder!));
                  }
                },
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'DbLensButton — ready-made trigger widget',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
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
    );
  }
}
