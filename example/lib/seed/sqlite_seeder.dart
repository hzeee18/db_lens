import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Seeder & schema demo untuk SQLite di example app.
abstract final class SqliteSeeder {
  /// Naikan nilai ini untuk memicu onUpgrade (drop + recreate + seed ulang).
  static const schemaVersion = 2;

  static const databaseFileName = 'example.db';

  /// Buka database example, jalankan schema + seed, return instance siap pakai.
  static Future<Database> open() async {
    final dbPath = join(await getDatabasesPath(), databaseFileName);

    return openDatabase(
      dbPath,
      version: schemaVersion,
      onCreate: createAndSeed,
      onUpgrade: onUpgrade,
    );
  }

  /// Drop semua tabel lalu buat ulang + seed (dipanggil sqflite saat upgrade).
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await db.execute('DROP TABLE IF EXISTS users');
    await db.execute('DROP TABLE IF EXISTS products');
    await createAndSeed(db, newVersion);
  }

  /// Buat schema dan isi data demo.
  static Future<void> createAndSeed(Database db, int version) async {
    await createTables(db);
    await seed(db);
  }

  /// DDL tabel demo.
  static Future<void> createTables(Database db) async {
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
  }

  /// Data sample: 100 users + 10 products.
  static Future<void> seed(Database db) async {
    final batch = db.batch();

    for (var i = 1; i <= 100; i++) {
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
  }
}
