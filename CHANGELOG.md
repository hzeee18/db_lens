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
