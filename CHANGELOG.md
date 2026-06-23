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
