import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:db_lens/db_lens.dart';

import 'screens/custom_ui_screen.dart';
import 'screens/embedded_panel_screen.dart';
import 'screens/history_demo_screen.dart';
import 'screens/presentation_modes_screen.dart';
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
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const HomeScreen(),
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
  const HomeScreen({super.key});

  List<_DemoItem> _demos() => [
        _DemoItem(
          title: 'Bottom Sheet (default)',
          subtitle: 'DbLens.open(context) — perilaku default sejak v0.0.1',
          icon: Icons.vertical_align_bottom,
          onTap: (context) => DbLens.open(context),
        ),
        _DemoItem(
          title: 'Full Page',
          subtitle: 'DbLens.openPage(context) — Navigator.push full-screen',
          icon: Icons.fullscreen,
          onTap: (context) => DbLens.openPage(context),
        ),
        _DemoItem(
          title: 'Presentation Mode shorthand',
          subtitle: 'DbLensConfig.presentationMode & mode: override',
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
          title: 'Custom UI (openCustom)',
          subtitle: 'DbLens.openCustom() — builder hook via Navigator.push',
          icon: Icons.widgets_outlined,
          onTap: (context) => DbLens.openCustom(
            context,
            builder: (context, controller) =>
                _MinimalCustomBrowser(controller: controller),
          ),
        ),
        _DemoItem(
          title: 'Custom UI (DbLensInspectorScope)',
          subtitle: 'Controller headless di-embed langsung di widget tree',
          icon: Icons.extension_outlined,
          builder: (context) => const CustomUiScreen(),
        ),
        _DemoItem(
          title: 'Change History',
          subtitle:
              'configureHistory · createHistoryController · DbLensHistorySheet',
          icon: Icons.history,
          builder: (context) => const HistoryDemoScreen(),
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
              'v0.0.6 — Custom UI & Headless API',
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

class _MinimalCustomBrowser extends StatefulWidget {
  const _MinimalCustomBrowser({required this.controller});

  final DbLensController controller;

  @override
  State<_MinimalCustomBrowser> createState() => _MinimalCustomBrowserState();
}

class _MinimalCustomBrowserState extends State<_MinimalCustomBrowser> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadBrowseSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller.browseLoading && !controller.hasBrowseSnapshot) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimal Custom Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                controller.browseRefreshing ? null : controller.refreshBrowse,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final source in controller.filteredBrowseSnapshot) ...[
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(source.sourceName),
              subtitle: Text('${source.totalRowCount} rows total'),
            ),
            for (final collection in source.collections)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                title: Text(collection.name),
                trailing: Text('${collection.rowCount}'),
                onTap: () async {
                  await controller.selectSource(source.sourceId);
                  await controller.selectCollection(collection.name);
                },
              ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
