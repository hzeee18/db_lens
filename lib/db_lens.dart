library db_lens;

// ── Core ─────────────────────────────────────────────────────────────────
export 'core/enums/db_lens_presentation_mode.dart';
export 'core/enums/source_type.dart';
export 'core/models/db_lens_config.dart';
export 'core/utils/sql_utils.dart';

// ── Data source contracts (custom registerSource) ─────────────────────────
export 'data/datasources/lens_datasource.dart';
export 'data/datasources/sqlite/sql_queryable_data_source.dart';
export 'data/registry/db_lens_registry.dart';

// ── Domain ───────────────────────────────────────────────────────────────
export 'domain/entities/collection_entity.dart';
export 'domain/entities/history_entry_entity.dart';
export 'domain/entities/row_entity.dart';
export 'domain/entities/source_entity.dart';
export 'domain/repositories/history_repository.dart';
export 'domain/repositories/lens_repository.dart';

// ── Facade ───────────────────────────────────────────────────────────────
export 'db_lens_facade.dart';

// ── Controllers (facade + sub-controller headless) ──────────────────────────
export 'presentation/controllers/db_lens_browse_controller.dart';
export 'presentation/controllers/db_lens_controller.dart';
export 'presentation/controllers/db_lens_edit_controller.dart';
export 'presentation/controllers/db_lens_history_controller.dart';
export 'presentation/controllers/db_lens_query_controller.dart';
export 'presentation/controllers/db_lens_query_history_controller.dart';
export 'presentation/controllers/db_lens_source_controller.dart';
export 'presentation/controllers/db_lens_table_controller.dart';

// ── Scope & layout (composition primitives) ───────────────────────────────
export 'presentation/layout/db_lens_layout.dart';
export 'presentation/scope/db_lens_controller_scope.dart';

// ── Extensibility hooks ──────────────────────────────────────────────────
export 'presentation/hooks/db_lens_action.dart';
export 'presentation/hooks/db_lens_cell_editor_builder.dart';
export 'presentation/hooks/db_lens_export_format.dart';
export 'presentation/hooks/db_lens_value_renderer.dart';

// ── State ────────────────────────────────────────────────────────────────
export 'presentation/state/db_lens_pagination.dart';
export 'presentation/state/db_lens_panel_models.dart';

// ── Theme ────────────────────────────────────────────────────────────────
export 'presentation/theme/db_lens_theme.dart';
export 'presentation/theme/db_lens_theme_data.dart';

// ── Pages ────────────────────────────────────────────────────────────────
export 'presentation/pages/db_lens_panel.dart';

// ── Widget library (built-in + custom UI) ─────────────────────────────────
export 'presentation/widgets/db_lens_button.dart';
export 'presentation/widgets/db_lens_cell_editor.dart';
export 'presentation/widgets/db_lens_chip.dart';
export 'presentation/widgets/db_lens_collection_list.dart';
export 'presentation/widgets/db_lens_data_grid.dart';
export 'presentation/widgets/db_lens_empty_state.dart';
export 'presentation/widgets/db_lens_error_view.dart';
export 'presentation/widgets/db_lens_highlighted_text.dart';
export 'presentation/widgets/db_lens_history_entry_view.dart';
export 'presentation/widgets/db_lens_history_header.dart';
export 'presentation/widgets/db_lens_history_panel.dart';
export 'presentation/widgets/db_lens_history_sheet.dart';
export 'presentation/widgets/db_lens_json_view.dart';
export 'presentation/widgets/db_lens_list_view.dart';
export 'presentation/widgets/db_lens_loading_view.dart';
export 'presentation/widgets/db_lens_pagination_bar.dart';
export 'presentation/widgets/db_lens_query_editor.dart';
export 'presentation/widgets/db_lens_query_history_list.dart';
export 'presentation/widgets/db_lens_row_json_sheet.dart';
export 'presentation/widgets/db_lens_search_bar.dart';
export 'presentation/widgets/db_lens_source_list.dart';
export 'presentation/widgets/db_lens_status_bar.dart';
export 'presentation/widgets/db_lens_table_view.dart';
export 'presentation/widgets/db_lens_toolbar.dart';
