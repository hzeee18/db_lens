# db_lens 🔍

A Flutter debug tool for inspecting SQLite and SharedPreferences directly on device — no adb, no external tools, no laptop needed.

> Designed for QA and developers. Works out of the box.

---

## Preview

| SQLite Browser | Pagination | SharedPreferences |
|:-:|:-:|:-:|
| <img src="screenshots/preview_sqlite.png" width="200"/> | <img src="screenshots/preview_pagination.png" width="200"/> | <img src="screenshots/preview_sharedprefs.png" width="200"/> |

---

## Installation

```yaml
dev_dependencies:
  db_lens: ^0.0.3
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

Drop it anywhere — app bar, drawer, debug menu, settings page.

```dart
// Default
DbLensButton()

// Custom
DbLensButton(
  label: 'Inspect Data',
  icon: Icons.bug_report,
  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
)
```

---

## Multiple Sources

```dart
DbLens.register('Main DB', mainDb);
DbLens.register('Cache DB', cacheDb);
DbLens.registerSharedPreferences('App Prefs', prefs);
```

Switch between sources inside the panel.

---

## Features

| | |
|---|---|
| 🗄️ | SQLite table browser |
| 🔑 | SharedPreferences inspector with key, type & value |
| 🔎 | Search across all columns |
| 📄 | Pagination (10 rows/page) |
| 🛠️ | Raw SQL query support |
| 🔄 | Refresh on demand |
| 📋 | Long-press cell to copy row as JSON |
| 💾 | Multiple source support |