import 'package:flutter/material.dart';

import '../controllers/db_lens_controller.dart';
import '../scope/db_lens_controller_scope.dart';
import '../theme/db_lens_theme.dart';
import 'db_lens_panel_widgets.dart';

/// Selector source — daftar chip yang bisa dicari, tap untuk pilih.
///
/// Membaca state dari [DbLensSourceController] (rebuild granular — tidak
/// ikut rebuild saat query/table berubah), tapi memanggil aksi lewat
/// facade [DbLensController] supaya efek silang (reset tabel saat ganti
/// source) tetap jalan.
class DbLensSourceList extends StatelessWidget {
  const DbLensSourceList({
    super.key,
    this.controller,
    this.searchable = true,
    this.searchHint = 'Search sources…',
  });

  final DbLensController? controller;
  final bool searchable;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    final c = controller ?? DbLensControllerScope.of(context);
    final theme = DbLensThemeScope.of(context);

    return AnimatedBuilder(
      animation: c.source,
      builder: (context, _) => DbLensSelectorField(
        icon: Icons.dns_outlined,
        label: 'Source',
        items: c.source.filteredSourceNames,
        selected: c.source.selectedSourceName,
        searchText: searchable ? c.source.sourceSearchText : '',
        onSearchChanged: searchable ? c.source.setSourceSearchText : null,
        searchHint: searchHint,
        theme: theme,
        onSelected: (name) {
          final source =
              c.source.sources.firstWhere((s) => s.name == name);
          c.selectSource(source.id);
        },
      ),
    );
  }
}
