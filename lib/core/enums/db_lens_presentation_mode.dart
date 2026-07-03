/// Mode presentasi panel bawaan lewat [DbLens.open].
///
/// Untuk menempel panel langsung di widget tree tanpa navigasi, pakai
/// [DbLens.buildPanel] — bukan bagian dari enum ini karena bukan mode
/// navigasi, melainkan cara berbeda menempatkan widget.
enum DbLensPresentationMode {
  /// Default: modal bottom sheet.
  bottomSheet,

  /// Full-screen route via Navigator.push.
  fullPage,
}
