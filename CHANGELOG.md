## Unreleased

Refactor arsitektur besar: `db_lens` dari "UI siap pakai" jadi "Database Inspector Framework" — bisa dipakai penuh (`DbLens.open()`) atau disusun sendiri dari widget dan controller kecil. Breaking change disengaja (pre-1.0, tidak ada usaha menjaga backward-compat dengan 0.0.6).

* **Controller**: `DbLensController` monolitik (848 baris) dipecah jadi 6 sub-controller kecil (`source`, `table`, `query`, `queryHistory`, `edit`, `browse`) digabung lewat `Listenable.merge`. Field lama seperti `controller.sources`/`controller.searchText`/`controller.pagination` pindah ke sub-controller terkait (mis. `controller.source.sources`, `controller.table.searchText`) — **tidak ada getter kompatibilitas**.
* **Scope**: `DbLensCustomHost` dan `DbLensInspectorScope` dihapus, diganti `DbLensControllerScope` (InheritedNotifier murni, tidak memaksa rebuild subtree) + `DbLensLayout` (slot-based: header/sidebar/toolbar/body/bottomBar).
* **Widget library baru**: `DbLensDataGrid`, `DbLensTableView`, `DbLensListView`, `DbLensJsonView`, `DbLensEmptyState`, `DbLensLoadingView`, `DbLensErrorView`, `DbLensCellEditor`, `DbLensSourceList`, `DbLensCollectionList`, `DbLensSearchBar`, `DbLensToolbar`, `DbLensStatusBar`, `DbLensQueryEditor`, `DbLensPaginationBar`, `DbLensHistoryPanel`, `DbLensHistoryEntryView`, `DbLensQueryHistoryList` — semua headless/reusable, diekspor lewat `db_lens.dart`. `DbLensPanel` bawaan kini disusun dari widget-widget publik ini, bukan implementasi paralel.
* **`DbLensHistoryPanel`** kini widget biasa yang tidak terkunci ke bottom sheet — bisa ditempel di `Scaffold`/tab custom. `DbLensHistorySheet` jadi wrapper modal tipis di atasnya.
* **Hook ekstensibilitas baru**: `DbLensValueRenderer`/`DbLensValueFormat`, `DbLensCellEditorBuilder`, `DbLensExportFormat`, `DbLensAction`.
* **`DbLensQueryHistoryController`** — riwayat eksekusi SQL per session (cap 40 entri), konsep baru untuk `DbLensQueryEditor`/`DbLensQueryHistoryList`.
* **Facade `DbLens`** disederhanakan: dihapus `unregister`, `databaseNames`, `getDatabase`, `getTables`, `getRows`, `getRowCount`, `getColumns`, `runRawQueryPaged`, `runRawQueryCount`, `openPage`, `openCustom`. `openPage`/`openCustom` dilebur ke `DbLens.open(context, config: ...)` + `DbLensControllerScope` langsung untuk custom shell.
* **API akses data langsung** untuk UI custom tanpa controller: `DbLens.registry` (akses `getSources()` / `LensDataSource` langsung), `DbLens.runRawQuery(source, sql)` (SELECT tanpa pagination), dan `DbLens.executeStatement(source, sql)`. Parameter `source` menerima sourceId maupun sourceName.
* **`DbLensPresentationMode.embedded`** dihapus — untuk embed pakai `DbLens.buildPanel()`.
* Use-case layer (11 file pass-through di `domain/usecases/`) dihapus; controller memanggil `LensRepository`/`HistoryRepository` langsung.
* `DbLensInfiniteScrollController` (dead code, tidak pernah dipakai) dihapus total.
* Validasi edit cell SharedPreferences dipindah dari controller ke `SharedPreferencesDataSource.updateCell` (perbaikan SRP).

**Technical debt yang sengaja ditunda** (bukan lupa — di luar cakupan refactor arsitektur widget/controller ini):
* `SourceType` masih enum tertutup, belum dibuka jadi tipe ekstensibel untuk custom data source di luar SQLite/SharedPreferences.
* Mekanisme polling history (`CollectionChangeTracker`) belum diganti event-based.

## 0.0.6

* Browse snapshot API untuk custom full-page inspector — `loadBrowseSnapshot()`, `refreshBrowse()`, `setBrowseSearchText()`, dan `filteredBrowseSnapshot` di `DbLensController`
* Model `BrowseSourceSnapshot` / `BrowseCollectionSnapshot` untuk daftar semua sumber + koleksi beserta row count di awal
* `DbLensCustomHost` menerima `controller` opsional (sama seperti `DbLensInspectorScope`) agar route detail bisa berbagi controller
* Example app: browse home + detail route dengan controller bersama
* Change History — pelacakan insert/update/delete otomatis lewat polling + diffing untuk semua collection yang terdaftar
* Riwayat disimpan permanen di database privat db_lens (`db_lens_history.db`) dengan opsi clear per source
* Panel History di level source (tombol di header) menampilkan entri dengan detail before/after JSON
* `DbLens.configureHistory()` dan `DbLens.createHistoryController()` sebagai API publik baru
* `LensDataSource.identityColumns()` — method baru untuk identitas baris saat diffing (breaking change minor untuk custom implementer)
* Export `DbLensController` sebagai public headless API untuk custom UI
* Tambah `DbLensPresentationMode` (bottomSheet, fullPage, embedded)
* Tambah `DbLens.openPage()` untuk inspector full-screen
* Tambah `DbLens.openCustom()` builder hook untuk shell UI custom sepenuhnya
* Tambah `DbLens.buildPanel()` untuk widget inspector yang di-embed
* Tambah `DbLensInspectorScope` untuk manajemen lifecycle controller di custom UI
* Extend `DbLensConfig` dengan `presentationMode` dan `fullscreenDialog`
* Dokumentasi pattern custom UI di README/doc/custom_ui.md
* Example app: demo full-page dan custom controller

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
