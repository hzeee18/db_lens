# Custom UI Guide

`db_lens` is a **Database Inspector Framework**. You can use the built-in panel as-is, or compose your own inspector from headless controllers and public widgets.

There are three integration levels:

| Level | Entry point | When to use |
|---|---|---|
| 1. Built-in panel | `DbLens.open()` | Fastest — bottom sheet or full-page inspector |
| 2. Embedded panel | `DbLens.buildPanel()` | Inspector lives inside your widget tree (debug tab, QA screen) |
| 3. Custom compose | `DbLensControllerScope` + widgets | Full control over layout, navigation, and behavior |

---

## Level 1 & 2 — Built-in and Embedded

```dart
// Modal bottom sheet (default)
DbLens.open(context);

// Full-screen route
DbLens.open(
  context,
  config: const DbLensConfig(
    presentationMode: DbLensPresentationMode.fullPage,
  ),
);

// Embedded — no navigation
DbLens.buildPanel(
  theme: DbLensThemeData.fromMaterialTheme(Theme.of(context)),
)
```

Pass an external controller to share state across routes:

```dart
final controller = DbLens.createController();
await controller.initialize();

DbLens.buildPanel(controller: controller)

// Later, on another route:
DbLensControllerScope(controller: controller, child: ...)
```

---

## Level 3 — Custom Compose

Wrap your widget tree with `DbLensControllerScope`. It provides a `DbLensController` (and theme) to all descendant widgets via `DbLensControllerScope.of(context)`.

```dart
DbLensControllerScope(
  theme: DbLensThemeData.fromMaterialTheme(Theme.of(context)),
  child: DbLensLayout(
    sidebar: const DbLensSourceList(),
    toolbar: const DbLensToolbar(actions: [DbLensRefreshAction()]),
    body: Builder(
      builder: (context) {
        final c = DbLensControllerScope.of(context);
        return AnimatedBuilder(
          animation: c.table,
          builder: (context, _) {
            final columns = c.activeColumns;
            return DbLensTableView(
              rows: c.visibleRows(columns: columns),
              columns: columns,
            );
          },
        );
      },
    ),
  ),
)
```

If you omit `controller`, the scope creates and manages one automatically (calls `initialize()` on mount, `dispose()` on unmount). If you pass your own, call `controller.initialize()` before mounting and dispose it yourself.

### Rebuild strategy

`DbLensControllerScope` does **not** wrap children in a global `AnimatedBuilder`. Each leaf widget listens to the specific sub-controller it needs, so typing in a search box does not rebuild unrelated widgets.

```dart
AnimatedBuilder(
  animation: controller.table,
  builder: (context, _) => DbLensSearchBar(
    onChanged: controller.table.setSearchText,
    showClear: controller.table.searchText.isNotEmpty,
    onClear: controller.table.clearSearch,
  ),
)
```

---

## Sub-controllers

`DbLensController` is a facade over six focused sub-controllers:

### `controller.source`

Sources, collections, and selection state.

```dart
controller.source.sources          // List<SourceEntity>
controller.source.selectedSourceId
controller.source.selectedCollection
controller.source.supportsRawSql

await controller.selectSource(sourceId);
await controller.selectCollection('users');
```

### `controller.table`

Row data, client-side search, and pagination.

```dart
controller.table.rows
controller.table.activeColumns
controller.table.searchText
controller.table.loading
controller.table.pagination

controller.table.setSearchText('foo');
await controller.table.refresh();
```

### `controller.query`

Raw SQL mode for SQLite sources.

```dart
controller.query.queryMode
controller.query.rows
controller.query.queryError

await controller.query.run('SELECT * FROM users WHERE age > 18');
controller.query.exit(); // back to table view
```

### `controller.queryHistory`

Per-session SQL execution history (40-entry cap).

```dart
controller.queryHistory.entries
controller.queryHistory.add(sql, rowCount: rows.length);
```

Used by `DbLensQueryEditor` and `DbLensQueryHistoryList`.

### `controller.edit`

Cell editing state.

```dart
controller.canEditCells
await controller.updateCellValue(column: 'name', newValue: 'Alice', row: row);
```

### `controller.browse`

Browse-all-sources snapshot (useful for custom home screens).

```dart
await controller.loadBrowseSnapshot();
controller.browse.filteredSnapshot  // List<BrowseSourceSnapshot>
controller.browse.setSearchText('users');
await controller.browse.refresh();
```

---

## Widget Library

All widgets are headless/reusable and exported from `package:db_lens/db_lens.dart`.

### Layout

| Widget | Purpose |
|---|---|
| `DbLensLayout` | Slot-based layout (header / sidebar / toolbar / body / bottomBar) |

### Data display

| Widget | Purpose |
|---|---|
| `DbLensSourceList` | Source selector list |
| `DbLensCollectionList` | Collection selector list |
| `DbLensTableView` | Table view with column headers |
| `DbLensListView` | Expandable row cards — search highlight, copy JSON, default cell edit |
| `DbLensDataGrid` | Grid-style data display |
| `DbLensJsonView` | Pretty-printed JSON view |
| `DbLensEmptyState` | Empty placeholder |
| `DbLensLoadingView` | Loading placeholder |
| `DbLensErrorView` | Error placeholder |

### Input & actions

| Widget | Purpose |
|---|---|
| `DbLensSearchBar` | Search input with clear button |
| `DbLensToolbar` | Toolbar slot |
| `DbLensRefreshAction` | Refresh icon button |
| `DbLensQueryEditor` | SQL input with history |
| `DbLensQueryHistoryList` | Session SQL history list |
| `DbLensCellEditor` | Type-aware cell edit dialog (type badge, validation) |
| `DbLensPaginationBar` | Page navigation |
| `DbLensStatusBar` | Status bar slot |
| `DbLensButton` | Ready-made trigger button |

### History

| Widget | Purpose |
|---|---|
| `DbLensHistoryHeader` | History title bar — back, search/filter toggles, tracking, clear |
| `DbLensHistoryPanel` | History entry list; optional `table` scope |
| `DbLensHistorySheet` | Bottom-sheet wrapper around header + panel |
| `DbLensHistoryEntryView` | Single entry detail — diff or raw JSON + copy |

### Utilities

| Widget / API | Purpose |
|---|---|
| `DbLensCellEdit.run()` | Default edit flow — dialog + save via callback or controller |
| `DbLensRowJsonSheet` | Row JSON bottom sheet |
| `DbLensHighlightedText` | Search highlight text |
| `DbLensChip` | Small label chip |

---

## Cell editing

`DbLensListView` opens the default edit dialog automatically when `canEditColumn` allows it and no custom `onEditCell` is provided — as long as a `DbLensControllerScope` ancestor exists:

```dart
DbLensListView(
  rows: rows,
  columns: columns,
  searchQuery: c.table.searchText,
  canEditColumn: (col) => c.canEditCells && col != '_rowid_',
)
```

For custom UI without a controller (e.g. direct `LensDataSource` access), pass `onSaveCell`:

```dart
DbLensListView(
  rows: rows,
  columns: columns,
  canEditColumn: _canEditField,
  isSQLite: source.sourceType == SourceType.sqlite,
  onSaveCell: (column, newValue, row) async {
    await source.updateCell(collection, column, newValue, row);
    await reload();
    return true;
  },
)
```

Override the dialog entirely with `onEditCell`, or call `DbLensCellEdit.run()` / `DbLensCellEditor.show()` directly.

---

## Direct Data Access (no controller)

For lightweight custom UI that does not need the full controller:

```dart
// List all registered sources
final sources = DbLens.registry.getSources();

// Run a SELECT (no pagination)
final rows = await DbLens.runRawQuery('Main DB', 'SELECT * FROM users LIMIT 10');

// Execute INSERT/UPDATE/DELETE/DDL
await DbLens.executeStatement('Main DB', 'DELETE FROM users WHERE id = 1');
```

The `source` parameter accepts either `sourceId` or `sourceName`.

---

## Extensibility Hooks

| Hook | Purpose |
|---|---|
| `DbLensValueRenderer` / `DbLensValueFormat` | Custom cell value rendering |
| `DbLensCellEditorBuilder` | Custom cell editor |
| `DbLensExportFormat` | Custom export format |
| `DbLensAction` | Custom toolbar / list actions |

---

## Change History

History UI is split into a header and a panel so you can embed it in a bottom sheet or a full-page `Scaffold`.

- **`DbLensHistoryHeader`** — title, optional `onBack`, search/filter toggle buttons (collapsed by default), tracking switch, clear.
- **`DbLensHistoryPanel`** — entry list. Pass `table` to scope to one collection (hides the table picker in filters).
- **`DbLensHistorySheet`** — thin modal wrapper; also accepts optional `table`.
- **`DbLensHistoryEntryView`** — per-entry diff (single-column for insert/delete, side-by-side for update) or raw JSON with copy.

```dart
DbLens.configureHistory(
  enabled: true,
  pollInterval: const Duration(seconds: 5),
);

final historyController = DbLens.createHistoryController();
await historyController.loadFor(sourceId);

// Full-page
Scaffold(
  body: Column(
    children: [
      DbLensHistoryHeader(
        controller: historyController,
        sourceName: 'Main DB',
        onBack: () => Navigator.pop(context),
      ),
      Expanded(
        child: DbLensHistoryPanel(
          controller: historyController,
          table: 'users', // optional
        ),
      ),
    ],
  ),
);

// Modal — all tables
await DbLensHistorySheet.show(
  context,
  controller: historyController,
  sourceName: 'Main DB',
);

// Modal — one table
await DbLensHistorySheet.show(
  context,
  controller: historyController,
  sourceName: 'Main DB',
  table: 'users',
);

historyController.dispose();
```

Filters (table + `insert` / `update` / `delete`) live on `DbLensHistoryController`. History tracking uses polling (`CollectionChangeTracker`) and is disabled in release builds.

---

## Example References

The `example/` app demonstrates every pattern:

| Screen | Pattern |
|---|---|
| `main.dart` | Quick start, `DbLensButton`, bottom sheet |
| `presentation_modes_screen.dart` | `DbLensConfig.presentationMode` |
| `embedded_panel_screen.dart` | `DbLens.buildPanel()` |
| `custom_ui_screen.dart` | `DbLensControllerScope` + public widgets, shared controller across routes |
| `history_demo_screen.dart` | `configureHistory`, `createHistoryController`, `DbLensHistoryHeader`, `DbLensHistorySheet` |
