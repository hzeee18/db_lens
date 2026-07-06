import 'package:flutter/material.dart';

/// Satu aksi kustom yang bisa diselipkan ke toolbar atau item list
/// (mis. tombol "History"/"Query" per source di [DbLensSourceList]) tanpa
/// fork widget.
class DbLensAction {
  const DbLensAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
