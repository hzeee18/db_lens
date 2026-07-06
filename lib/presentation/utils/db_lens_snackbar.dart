import 'package:flutter/material.dart';

/// Warna gelap netral untuk snackbar sukses (setara neutral900).
const _kDbLensSnackSuccessBackground = Color(0xFF111827);

void showDbLensSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 2),
      backgroundColor:
          isError ? Colors.redAccent : _kDbLensSnackSuccessBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
    ),
  );
}
