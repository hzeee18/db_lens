/// Mode presentasi panel DbLens.
enum DbLensPresentationMode {
  /// Default: modal bottom sheet (perilaku saat ini).
  bottomSheet,

  /// Full-screen route via Navigator.push.
  fullPage,

  /// Tanpa navigasi — caller menyediakan builder/widget sendiri
  /// (dipakai lewat DbLens.buildPanel / DbLens.openCustom).
  embedded,
}
