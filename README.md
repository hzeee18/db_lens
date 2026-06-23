# db_lens 🔍

A Flutter debug tool for inspecting SQLite and SharedPreferences directly on device — no adb, no external tools, no laptop needed.

> Designed for QA and developers. Works out of the box. Hidden in release builds (`kReleaseMode`).

---

## Preview

| SQLite Browser | Pagination | SharedPreferences |
|:-:|:-:|:-:|
| <img src="screenshots/preview_sqlite.png" width="200"/> | <img src="screenshots/preview_pagination.png" width="200"/> | <img src="screenshots/preview_sharedprefs.png" width="200"/> |

---

## Installation

```yaml
dev_dependencies:
  db_lens: ^0.0.4
```

---

## Quick Start

```dart
import 'package:db_lens/db_lens.dart';

// SQLite
final db = await openDatabase('my_app.db');
DbLens.register('Main DB', db);

// SharedPreferences
final prefs = await SharedPreferences.getInstance();
DbLens.registerSharedPreferences('App Prefs', prefs);

// Open the inspector
DbLens.open(context);
```

---

## DbLensButton

Drop it anywhere — app bar, drawer, debug menu, settings page. Automatically hidden in release builds.

```dart
// Default
DbLensButton()

// Custom label, icon, and style
DbLensButton(
  label: 'Inspect Data',
  icon: Icons.bug_report,
  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
)
```

---

## Dynamic Theme

Match the panel to your app's `MaterialApp` theme, or pass custom colors.

```dart
DbLens.open(
  context,
  theme: DbLensThemeData.fromMaterialTheme(Theme.of(context)),
);

// Or custom tokens
DbLens.open(
  context,
  theme: const DbLensThemeData(accent: Colors.teal),
);
```

---

## Multiple Sources

```dart
DbLens.register('Main DB', mainDb);
DbLens.register('Cache DB', cacheDb);
DbLens.registerSharedPreferences('App Prefs', prefs);
```

Switch between sources inside the panel. Search and filter source and collection lists in real time.

---

## Features

| | |
|---|---|
| 🗄️ | SQLite table browser with pagination |
| 🔑 | SharedPreferences inspector (`key`, `type`, `value`) |
| 🔎 | Search rows across all columns; searchable source & collection selectors |
| 📄 | Pagination (configurable via `DbLensConfig.pageSize`, default 10) |
| 🛠️ | Raw SQL query (SQLite); auto-select table on simple `SELECT` |
| 🎨 | Table / JSON view toggle — current page as pretty-printed JSON array |
| 📋 | Tap row → JSON bottom sheet; long-press → copy or edit cell |
| ✏️ | Edit cell values (SQLite `UPDATE` / SharedPreferences `set*`) |
| 📤 | Export — copy all as JSON; export SQLite to Excel (`.xlsx`) |
| 🎨 | `DbLensThemeData` — customizable panel colors |
| 🔄 | Refresh on demand |
| 💾 | Multiple source support |
| 🔒 | No-op in release builds |

---

## Configuration

```dart
DbLens.open(
  context,
  config: const DbLensConfig(
    pageSize: 20,
    enablePrefetch: true,
  ),
);
```

---

## Example App

Run the included example to try every feature (SQLite + SharedPreferences, themed open, export, edit, JSON view):

```bash
cd example
flutter run
```

---

## License

See [LICENSE](LICENSE).
