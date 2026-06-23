import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Seeder & schema demo untuk SQLite di example app.
abstract final class SqliteSeeder {
  /// Naikan nilai ini untuk memicu onUpgrade (drop + recreate + seed ulang).
  static const schemaVersion = 3;

  static const databaseFileName = 'example.db';

  static const _categories = [
    'electronics',
    'books',
    'food',
    'clothing',
    'home',
  ];

  static const _orderStatuses = [
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

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
    await db.execute('DROP TABLE IF EXISTS orders');
    await db.execute('DROP TABLE IF EXISTS products');
    await db.execute('DROP TABLE IF EXISTS users');
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
        age INTEGER,
        is_premium INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        category TEXT,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        ordered_at TEXT NOT NULL
      )
    ''');
  }

  /// Data sample: 50+ baris per tabel.
  static Future<void> seed(Database db) async {
    final batch = db.batch();
    final baseDate = DateTime(2024, 1, 1);

    for (var i = 1; i <= 55; i++) {
      final createdAt = baseDate.add(Duration(days: i * 3));
      batch.insert('users', {
        'name': 'User $i',
        'email': 'user$i@example.com',
        'age': 18 + (i % 50),
        'is_premium': i % 4 == 0 ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      });
    }

    for (var i = 1; i <= 55; i++) {
      batch.insert('products', {
        'name': 'Product $i',
        'price': double.parse((i * 9.99).toStringAsFixed(2)),
        'stock': i * 5,
        'category': _categories[i % _categories.length],
        'description': 'Description for product $i in the demo catalog.',
      });
    }

    for (var i = 1; i <= 55; i++) {
      final quantity = (i % 5) + 1;
      final unitPrice = double.parse(((i % 55 + 1) * 9.99).toStringAsFixed(2));
      final orderedAt = baseDate.add(Duration(hours: i * 12));
      batch.insert('orders', {
        'user_id': (i % 55) + 1,
        'product_id': (i % 55) + 1,
        'quantity': quantity,
        'total': double.parse((unitPrice * quantity).toStringAsFixed(2)),
        'status': _orderStatuses[i % _orderStatuses.length],
        'ordered_at': orderedAt.toIso8601String(),
      });
    }

    await batch.commit();
  }
}
