import 'package:flutter/widgets.dart';

/// Hook untuk mengganti dialog edit sel bawaan ([DbLensCellEditor]) dengan
/// tampilan kustom (mis. date picker untuk kolom tanggal, dropdown untuk
/// kolom enum) tanpa fork widget.
///
/// Kembalikan nilai baru untuk disimpan (boleh `null` — itu nilai yang sah,
/// bukan pembatalan). Kalau pengguna membatalkan, lempar
/// [DbLensCellEditCancelled] — pemanggil (mis. [DbLensListView]/
/// [DbLensTableView] pengguna) menangkapnya untuk tahu tidak perlu
/// menyimpan apa pun.
typedef DbLensCellEditorBuilder = Future<Object?> Function(
  BuildContext context,
  String column,
  Object? currentValue,
);

/// Dilempar oleh [DbLensCellEditorBuilder] ketika pengguna membatalkan edit.
class DbLensCellEditCancelled implements Exception {
  const DbLensCellEditCancelled();

  @override
  String toString() => 'DbLensCellEditCancelled';
}
