import 'package:flutter/material.dart';

import '../controllers/db_lens_controller.dart';
import '../scope/db_lens_controller_scope.dart';
import '../theme/db_lens_theme.dart';
import 'db_lens_panel_widgets.dart';

/// Selector collection untuk source yang sedang terpilih — daftar chip yang
/// bisa dicari, tap untuk pilih.
class DbLensCollectionList extends StatelessWidget {
  const DbLensCollectionList({
    super.key,
    this.controller,
    this.searchable = true,
    this.searchHint = 'Search collections…',
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
        icon: Icons.table_rows_outlined,
        label: 'Collection',
        items: c.source.filteredCollections,
        selected: c.source.selectedCollection,
        searchText: searchable ? c.source.collectionSearchText : '',
        onSearchChanged: searchable ? c.source.setCollectionSearchText : null,
        searchHint: searchHint,
        theme: theme,
        onSelected: c.selectCollection,
      ),
    );
  }
}
