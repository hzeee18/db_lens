# db_lens Example

Demonstrates every integration pattern for the Database Inspector Framework.

## Run

```bash
flutter run
```

The example seeds a SQLite database and SharedPreferences, then registers both with `DbLens`.

## Demos

| Demo | What it shows |
|---|---|
| **Bottom Sheet (default)** | `DbLens.open(context)` — default `presentationMode` |
| **Full Page** | `DbLens.open(context, config: DbLensConfig(presentationMode: fullPage))` |
| **Presentation Mode** | Side-by-side comparison of `bottomSheet` vs `fullPage` |
| **Embedded Panel** | `DbLens.buildPanel()` embedded directly in a `Scaffold` body |
| **Custom UI** | `DbLensControllerScope` + public widgets (`DbLensSearchBar`, `DbLensListView`, `DbLensQueryEditor`, etc.) with a shared controller across routes |
| **Change History** | `DbLens.configureHistory()`, `DbLens.createHistoryController()`, `DbLensHistorySheet` |

## Files

```
lib/
├── main.dart                          # Home screen with demo list
├── screens/
│   ├── custom_ui_screen.dart          # Custom compose pattern
│   ├── embedded_panel_screen.dart     # buildPanel pattern
│   ├── history_demo_screen.dart       # Change history
│   └── presentation_modes_screen.dart # presentationMode config
└── seed/
    ├── sqlite_seeder.dart             # Sample SQLite data
    └── shared_preferences_seeder.dart # Sample prefs data
```

See [doc/custom_ui.md](../doc/custom_ui.md) for the full custom UI guide.
