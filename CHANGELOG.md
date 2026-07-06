## 1.0.0

Major architecture refactor: `db_lens` from "ready-to-use UI" to "Database Inspector Framework" — usable out of the box (`DbLens.open()`) or composed from small widgets and controllers. Intentional breaking change (pre-1.0, no effort to maintain backward compatibility with 0.0.6).

* **Controller**: Monolithic `DbLensController` (848 lines) split into 6 small sub-controllers (`source`, `table`, `query`, `queryHistory`, `edit`, `browse`) combined via `Listenable.merge`. Legacy fields such as `controller.sources`/`controller.searchText`/`controller.pagination` moved to related sub-controllers (e.g. `controller.source.sources`, `controller.table.searchText`) — **no compatibility getters**.
* **Scope**: `DbLensCustomHost` and `DbLensInspectorScope` removed, replaced by `DbLensControllerScope` (pure InheritedNotifier, does not force subtree rebuild) + `DbLensLayout` (slot-based: header/sidebar/toolbar/body/bottomBar).
* **New widget library**: `DbLensDataGrid`, `DbLensTableView`, `DbLensListView`, `DbLensJsonView`, `DbLensEmptyState`, `DbLensLoadingView`, `DbLensErrorView`, `DbLensCellEditor`, `DbLensSourceList`, `DbLensCollectionList`, `DbLensSearchBar`, `DbLensToolbar`, `DbLensStatusBar`, `DbLensQueryEditor`, `DbLensPaginationBar`, `DbLensHistoryPanel`, `DbLensHistoryEntryView`, `DbLensQueryHistoryList` — all headless/reusable, exported via `db_lens.dart`. Built-in `DbLensPanel` is now composed from these public widgets, not a parallel implementation.
* **`DbLensHistoryPanel`** is now a regular widget not locked to a bottom sheet — can be placed in a custom `Scaffold`/tab. `DbLensHistorySheet` becomes a thin modal wrapper on top.
* **New extensibility hooks**: `DbLensValueRenderer`/`DbLensValueFormat`, `DbLensCellEditorBuilder`, `DbLensExportFormat`, `DbLensAction`.
* **`DbLensQueryHistoryController`** — per-session SQL execution history (40-entry cap), new concept for `DbLensQueryEditor`/`DbLensQueryHistoryList`.
* **`DbLens` facade simplified**: removed `unregister`, `databaseNames`, `getDatabase`, `getTables`, `getRows`, `getRowCount`, `getColumns`, `runRawQueryPaged`, `runRawQueryCount`, `openPage`, `openCustom`. `openPage`/`openCustom` merged into `DbLens.open(context, config: ...)` + `DbLensControllerScope` directly for custom shells.
* **Direct data access API** for custom UI without a controller: `DbLens.registry` (direct access to `getSources()` / `LensDataSource`), `DbLens.runRawQuery(source, sql)` (SELECT without pagination), and `DbLens.executeStatement(source, sql)`. The `source` parameter accepts sourceId or sourceName.
* **`DbLensPresentationMode.embedded`** removed — use `DbLens.buildPanel()` for embedding.
* Use-case layer (11 pass-through files in `domain/usecases/`) removed; controllers call `LensRepository`/`HistoryRepository` directly.
* `DbLensInfiniteScrollController` (dead code, never used) removed entirely.
* SharedPreferences cell edit validation moved from controller to `SharedPreferencesDataSource.updateCell` (SRP fix).

**Intentionally deferred technical debt** (not forgotten — out of scope for this widget/controller architecture refactor):
* `SourceType` remains a closed enum, not yet opened into an extensible type for custom data sources beyond SQLite/SharedPreferences.
* History polling mechanism (`CollectionChangeTracker`) not yet replaced with event-based approach.

## 0.0.6

* Browse snapshot API for custom full-page inspector — `loadBrowseSnapshot()`, `refreshBrowse()`, `setBrowseSearchText()`, and `filteredBrowseSnapshot` on `DbLensController`
* `BrowseSourceSnapshot` / `BrowseCollectionSnapshot` models for listing all sources + collections with row counts upfront
* `DbLensCustomHost` accepts optional `controller` (same as `DbLensInspectorScope`) so detail routes can share a controller
* Example app: browse home + detail route with shared controller
* Change History — automatic insert/update/delete tracking via polling + diffing for all registered collections
* History persisted in db_lens private database (`db_lens_history.db`) with per-source clear option
* Source-level History panel (header button) shows entries with before/after JSON details
* `DbLens.configureHistory()` and `DbLens.createHistoryController()` as new public APIs
* `LensDataSource.identityColumns()` — new method for row identity during diffing (minor breaking change for custom implementers)
* Export `DbLensController` as public headless API for custom UI
* Add `DbLensPresentationMode` (bottomSheet, fullPage, embedded)
* Add `DbLens.openPage()` for full-screen inspector
* Add `DbLens.openCustom()` builder hook for fully custom UI shells
* Add `DbLens.buildPanel()` for embedded inspector widget
* Add `DbLensInspectorScope` for controller lifecycle management in custom UI
* Extend `DbLensConfig` with `presentationMode` and `fullscreenDialog`
* Custom UI pattern documentation in README/doc/custom_ui.md
* Example app: full-page and custom controller demos

# 0.0.5

* Remove Excel export and drop `excel` / `share_plus` dependencies
* Replace export menu with a dedicated copy-all-JSON toolbar button
* `DbLensThemeData.fromMaterialTheme()` uses a fixed warm palette (accent still follows app primary)
* Panel typography uses the default font instead of monospace

## 0.0.4

* Dynamic theme support via `DbLensThemeData` and `DbLensThemeData.fromMaterialTheme()`
* Searchable source and collection selectors with highlighted matches
* JSON view mode — toggle current page rows as a pretty-printed JSON array
* Row JSON bottom sheet — tap a row to inspect; edit full row JSON when editing is allowed
* Edit cell values (long-press) for SQLite and SharedPreferences
* Copy toolbar — copy all rows as JSON
* Raw SQL auto-selects collection from simple `FROM` clause; complex queries stay in custom result view
* Smooth single-scroll layout using slivers (fixes nested scroll conflicts)
* `kReleaseMode` guard on `DbLens.open()` and `DbLensButton`
* Example app showcase with seeded SQLite & SharedPreferences data

## 0.0.3

* Add screenshots to pub.dev listing

## 0.0.2

* Support SharedPreferences as a data source with key, type, value columns
* Add SQLite raw query support
* Add search across all data sources
* Add refresh support

## 0.0.1

* Initial release
* Floating draggable debug button
* SQLite table browser via sqflite
* Paginated row viewer (50 rows/page)
* Long-press to copy cell value
* Multiple database support
* Auto-hidden in release builds
