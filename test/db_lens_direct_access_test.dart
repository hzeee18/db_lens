import 'package:db_lens/db_lens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Alur akses data langsung tanpa controller — pola yang dipakai konsumen
/// yang menyusun UI inspector sepenuhnya sendiri di atas facade [DbLens].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> openSeededDb() {
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)',
        );
        await db.insert('users', {'name': 'Alice'});
        await db.insert('users', {'name': 'Bob'});
      },
    );
  }

  test('DbLens.registry.getSources() memaparkan LensDataSource langsung',
      () async {
    final db = await openSeededDb();
    DbLens.register('Direct DB', db);
    addTearDown(() => DbLens.unregisterSource('Direct DB'));

    final sources = DbLens.registry.getSources();
    expect(sources, isNotEmpty);

    final source = sources.singleWhere((s) => s.sourceName == 'Direct DB');
    expect(source.sourceType, SourceType.sqlite);
    expect(await source.collections(), contains('users'));
    expect(await source.count('users'), 2);
    expect(await source.columnNames('users'), containsAll(['id', 'name']));

    final rows = await source.rows('users', 20, 0);
    expect(rows, hasLength(2));

    await db.close();
  });

  test('DbLens.runRawQuery / executeStatement menerima sourceName', () async {
    final db = await openSeededDb();
    DbLens.register('Query DB', db);
    addTearDown(() => DbLens.unregisterSource('Query DB'));

    final rows = await DbLens.runRawQuery(
      'Query DB',
      "SELECT * FROM users WHERE name = 'Alice'",
    );
    expect(rows, hasLength(1));
    expect(rows.first['name'], 'Alice');

    await DbLens.executeStatement(
      'Query DB',
      "INSERT INTO users (name) VALUES ('Cara')",
    );
    final all = await DbLens.runRawQuery('Query DB', 'SELECT * FROM users');
    expect(all, hasLength(3));

    await db.close();
  });

  test('runRawQuery melempar untuk source yang tidak terdaftar', () async {
    expect(
      () => DbLens.runRawQuery('missing', 'SELECT 1'),
      throwsStateError,
    );
  });
}
