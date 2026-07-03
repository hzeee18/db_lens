import 'package:db_lens/data/datasources/sqlite/sqlite_data_source.dart';
import 'package:db_lens/data/history/collection_change_tracker.dart';
import 'package:db_lens/data/history/history_data_source.dart';
import 'package:db_lens/data/history/history_database.dart';
import 'package:db_lens/domain/entities/history_entry_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database userDb;
  late HistoryDataSource historyDataSource;
  late SqliteDataSource source;
  late CollectionChangeTracker tracker;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await HistoryDatabase.instance.closeForTesting();

    userDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      },
    );

    await userDb.insert('items', {'name': 'alpha'});

    historyDataSource = HistoryDataSource(HistoryDatabase.instance);
    await historyDataSource.clearAll();
    source = SqliteDataSource(
      sourceId: 'test-db',
      sourceName: 'Test DB',
      database: userDb,
    );
    tracker = CollectionChangeTracker(
      source: source,
      historyDataSource: historyDataSource,
    );
  });

  tearDown(() async {
    tracker.stop();
    await userDb.close();
    await HistoryDatabase.instance.closeForTesting();
  });

  Future<List<HistoryEntry>> history() =>
      historyDataSource.getForSource('test-db');

  test('seed baseline tidak menulis history', () async {
    await tracker.seedNow();
    await tracker.pollNow();

    expect(await history(), isEmpty);
  });

  test('mendeteksi insert dari luar db_lens', () async {
    await tracker.seedNow();

    await userDb.insert('items', {'name': 'beta'});
    await tracker.pollNow();

    final entries = await history();
    expect(entries, hasLength(1));
    expect(entries.first.changeType, HistoryChangeType.insert);
    expect(entries.first.collection, 'items');
    expect(entries.first.afterJson, contains('beta'));
    expect(entries.first.beforeJson, isNull);
  });

  test('mendeteksi update dari luar db_lens', () async {
    await tracker.seedNow();

    await userDb.update('items', {'name': 'alpha-updated'}, where: 'id = 1');
    await tracker.pollNow();

    final entries = await history();
    expect(entries, hasLength(1));
    expect(entries.first.changeType, HistoryChangeType.update);
    expect(entries.first.beforeJson, contains('alpha'));
    expect(entries.first.afterJson, contains('alpha-updated'));
    expect(entries.first.changedColumns, contains('name'));
  });

  test('mendeteksi delete dari luar db_lens', () async {
    await tracker.seedNow();

    await userDb.delete('items', where: 'id = 1');
    await tracker.pollNow();

    final entries = await history();
    expect(entries, hasLength(1));
    expect(entries.first.changeType, HistoryChangeType.delete);
    expect(entries.first.beforeJson, contains('alpha'));
    expect(entries.first.afterJson, isNull);
  });
}
