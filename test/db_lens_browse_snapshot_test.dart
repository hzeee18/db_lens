import 'package:db_lens/db_lens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() {
    for (final name in List.of(DbLens.databaseNames)) {
      DbLens.unregister(name);
    }
  });

  test('loadBrowseSnapshot lists all sources, collections, and row counts',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)',
        );
        await db.execute(
          'CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT)',
        );
        await db.insert('users', {'name': 'Alice'});
        await db.insert('users', {'name': 'Bob'});
        await db.insert('posts', {'title': 'Hello'});
      },
    );
    DbLens.register('App DB', db);

    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    DbLens.registerSharedPreferences('Settings', prefs);

    final controller = DbLens.createController();
    final snapshot = await controller.loadBrowseSnapshot();

    expect(snapshot, hasLength(2));

    final appDb = snapshot.firstWhere((s) => s.sourceName == 'App DB');
    expect(appDb.collections, hasLength(2));
    expect(
      appDb.collections.map((c) => c.name).toList(),
      containsAll(['users', 'posts']),
    );
    expect(
      appDb.collections.firstWhere((c) => c.name == 'users').rowCount,
      2,
    );
    expect(
      appDb.collections.firstWhere((c) => c.name == 'posts').rowCount,
      1,
    );

    final settings = snapshot.firstWhere((s) => s.sourceName == 'Settings');
    expect(settings.collections, isNotEmpty);
    expect(settings.totalRowCount, greaterThan(0));

    controller.dispose();
    await db.close();
  });

  test('setBrowseSearchText filters snapshot by source and collection names',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE alpha (id INTEGER PRIMARY KEY)');
        await db.execute('CREATE TABLE beta (id INTEGER PRIMARY KEY)');
      },
    );
    DbLens.register('Primary', db);

    final controller = DbLens.createController();
    await controller.loadBrowseSnapshot();

    controller.setBrowseSearchText('beta');
    expect(controller.filteredBrowseSnapshot, hasLength(1));
    expect(
      controller.filteredBrowseSnapshot.first.collections,
      hasLength(1),
    );
    expect(
      controller.filteredBrowseSnapshot.first.collections.first.name,
      'beta',
    );

    controller.setBrowseSearchText('primary');
    expect(controller.filteredBrowseSnapshot, hasLength(1));
    expect(
      controller.filteredBrowseSnapshot.first.collections,
      hasLength(2),
    );

    controller.dispose();
    await db.close();
  });

  test('refreshBrowse reloads row counts', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE items (id INTEGER PRIMARY KEY, value TEXT)',
        );
      },
    );
    DbLens.register('Counter DB', db);

    final controller = DbLens.createController();
    await controller.loadBrowseSnapshot();
    expect(
      controller.browseSnapshot.first.collections.first.rowCount,
      0,
    );

    await db.insert('items', {'value': 'one'});
    await controller.refreshBrowse();

    expect(
      controller.browseSnapshot.first.collections.first.rowCount,
      1,
    );

    controller.dispose();
    await db.close();
  });
}
