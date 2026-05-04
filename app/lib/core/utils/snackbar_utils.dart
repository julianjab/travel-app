import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';

/// Shows a floating error SnackBar with the standard error message.
///
/// Default message: 'Algo salió mal. Intentá de nuevo.'
/// Used across all mutation screens (create, edit, delete, archive).
void showErrorSnackBar(BuildContext context, [String? message]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message ?? 'Algo salió mal. Intentá de nuevo.'),
      backgroundColor: VamosColors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Shows a floating success SnackBar with the provided [message].
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: VamosColors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
