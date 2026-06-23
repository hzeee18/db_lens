import 'package:shared_preferences/shared_preferences.dart';

/// Seeder data demo untuk SharedPreferences di example app.
abstract final class SharedPreferencesSeeder {
  static const seedVersionKey = '_db_lens_seed_version';
  static const currentSeedVersion = 3;

  /// Menulis data sample ke [prefs].
  ///
  /// Lewati jika [force] false dan seed version sudah cocok.
  static Future<void> seed(
    SharedPreferences prefs, {
    bool force = false,
  }) async {
    final existing = prefs.getInt(seedVersionKey);
    if (!force && existing == currentSeedVersion) return;

    await prefs.setString('app_theme', 'dark');
    await prefs.setString('app_locale', 'id_ID');
    await prefs.setString('user_token', 'demo_token_abc123xyz');

    await prefs.setInt('login_count', 42);

    await prefs.setDouble('cart_total', 129.99);
    await prefs.setDouble('last_rating', 4.5);

    await prefs.setBool('biometric_login', true);
    await prefs.setBool('onboarding_done', true);
    await prefs.setBool('notifications_enabled', false);

    await prefs.setStringList(
      'favorite_categories',
      ['electronics', 'books', 'food'],
    );

    await prefs.setInt(seedVersionKey, currentSeedVersion);
  }

  /// Hapus semua key demo (kecuali seed version) — berguna saat testing ulang.
  static Future<void> clearDemoData(SharedPreferences prefs) async {
    const demoKeys = [
      'app_theme',
      'app_locale',
      'user_token',
      'login_count',
      'cart_total',
      'last_rating',
      'biometric_login',
      'onboarding_done',
      'notifications_enabled',
      'favorite_categories',
    ];

    for (final key in demoKeys) {
      await prefs.remove(key);
    }
    await prefs.remove(seedVersionKey);
  }
}
