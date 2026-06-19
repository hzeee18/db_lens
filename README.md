# db_lens 🔍

A Flutter debug tool for QA and developers to inspect SQLite (sqflite) databases directly on device — no external tools, no adb, no VS Code needed.

---

## Installation

```yaml
dev_dependencies:
  db_lens: ^0.0.1
```

---

## Usage

### 1. Register your database

```dart
import 'package:db_lens/db_lens.dart';

final db = await openDatabase('my_app.db');
DbLens.register('Main DB', db);
```

### 2a. Use the ready-made button

Drop `DbLensButton` anywhere — drawer, settings page, debug menu, etc.

```dart
import 'package:db_lens/db_lens.dart';

// Default
DbLensButton()

// Custom
DbLensButton(
  label: 'Inspect Database',
  icon: Icons.bug_report,
)
```

### 2b. Or open manually

```dart
DbLens.open(context);
```

---

## Multiple Databases

```dart
DbLens.register('Main DB', mainDb);
DbLens.register('Cache DB', cacheDb);
```

Switch between them inside the panel.

---

## Features

- 🔍 Browse all tables and rows
- 📄 Pagination (50 rows/page)  
- 📋 Long-press cell to copy value
- 💾 Multiple database support
- 🎯 Flexible — use `DbLensButton` or call `DbLens.open(context)` manually
