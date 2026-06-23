import 'package:db_lens/presentation/state/db_lens_pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DbLensPaginationController', () {
    test('nextPage loads the following page with correct offset', () async {
      final fetches = <Map<String, int>>[];
      final controller = DbLensPaginationController<String>(
        pageSize: 10,
        enablePrefetch: false,
        fetchPage: ({
          required int page,
          required int pageSize,
          required int offset,
          required bool refreshTotal,
        }) async {
          fetches.add({
            'page': page,
            'offset': offset,
            'refreshTotal': refreshTotal ? 1 : 0,
          });
          final start = offset;
          final rows = List<String>.generate(
            pageSize,
            (index) => 'row-${start + index}',
          );
          return DbLensPageData(
            rows: rows,
            totalRows: 25,
            page: page,
          );
        },
      );

      await controller.loadPage(0);
      expect(controller.page, 0);
      expect(controller.rows.first, 'row-0');
      expect(controller.canGoNext, isTrue);

      await controller.nextPage();
      expect(controller.page, 1);
      expect(controller.rows.first, 'row-10');
      expect(fetches.last['page'], 1);
      expect(fetches.last['offset'], 10);
    });

    test('prefetch hit does not leave isLoading stuck', () async {
      final controller = DbLensPaginationController<int>(
        pageSize: 5,
        enablePrefetch: true,
        fetchPage: ({
          required int page,
          required int pageSize,
          required int offset,
          required bool refreshTotal,
        }) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return DbLensPageData(
            rows: List<int>.generate(pageSize, (index) => offset + index),
            totalRows: 20,
            page: page,
          );
        },
      );

      await controller.loadPage(0);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final jumpFuture = controller.jumpToPage(3);
      final prefetchFuture = controller.nextPage();
      await Future.wait([jumpFuture, prefetchFuture]);

      expect(controller.isLoading, isFalse);
      expect(controller.page, anyOf(1, 3));
      expect(controller.canGoNext || controller.canGoPrevious, isTrue);
    });

    test('stale fetch does not overwrite newer page', () async {
      final controller = DbLensPaginationController<String>(
        pageSize: 5,
        enablePrefetch: false,
        fetchPage: ({
          required int page,
          required int pageSize,
          required int offset,
          required bool refreshTotal,
        }) async {
          final delay = page == 1 ? 50 : 5;
          await Future<void>.delayed(Duration(milliseconds: delay));
          return DbLensPageData(
            rows: ['page-$page'],
            totalRows: 15,
            page: page,
          );
        },
      );

      await controller.loadPage(0);
      final slow = controller.loadPage(1);
      await controller.loadPage(2);
      await slow;

      expect(controller.page, 2);
      expect(controller.rows, ['page-2']);
      expect(controller.isLoading, isFalse);
    });

    test('refresh reloads current page and total count', () async {
      var dbCount = 12;
      late final DbLensPaginationController<int> controller;
      controller = DbLensPaginationController<int>(
        pageSize: 5,
        enablePrefetch: false,
        fetchPage: ({
          required int page,
          required int pageSize,
          required int offset,
          required bool refreshTotal,
        }) async {
          return DbLensPageData(
            rows: [page],
            totalRows: refreshTotal ? dbCount : controller.totalRows,
            page: page,
          );
        },
      );

      await controller.loadPage(0);
      expect(controller.totalRows, 12);

      dbCount = 20;
      await controller.refresh();
      expect(controller.page, 0);
      expect(controller.totalRows, 20);
      expect(controller.rows, [0]);
    });
  });
}
