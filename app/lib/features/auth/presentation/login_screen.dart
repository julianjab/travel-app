import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_logo.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/features/auth/application/auth_notifier.dart';

/// Splash / login screen (E0-06).
///
/// Shown when the user is not authenticated. Provides Google and Apple
/// Sign-In buttons. Design is intentionally minimal — functional only.
/// Navigation to /trips is handled by the router redirect, not here.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authActions = ref.watch(authActionsProvider);
    final isLoading = authActions.isLoading;

    // Show SnackBar on error.
    ref.listen<AsyncValue<void>>(authActionsProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _friendlyError(error),
                style: VamosTypography.bodyMedium.copyWith(
                  color: VamosColors.textOnDark,
                ),
              ),
              backgroundColor: VamosColors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: VamosColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VamosSpacing.lg),
          child: Column(
            children: [
              // Top spacer — push logo to ~40% from top.
              const Spacer(flex: 3),

              // Logo
              const VamosLogo(size: 56),

              const SizedBox(height: VamosSpacing.sm),

              // Tagline
              Text(
                'Viajá con tu gente',
                style: VamosTypography.bodyMedium.copyWith(
                  color: VamosColors.text3,
                ),
              ),

              // Bottom spacer — buttons towards 2/3 of screen.
              const Spacer(flex: 2),

              // Google Sign-In button
              _SignInButton(
                label: 'Continuar con Google',
                icon: _GoogleIcon(),
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authActionsProvider.notifier)
                        .signInWithGoogle(),
              ),

              const SizedBox(height: VamosSpacing.md),

              // Apple Sign-In button (iOS only)
              if (Platform.isIOS) ...[
                _SignInButton(
                  label: 'Continuar con Apple',
                  icon: const Icon(
                    Icons.apple,
                    size: 22,
                    color: VamosColors.text,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authActionsProvider.notifier)
                          .signInWithApple(),
                ),
                const SizedBox(height: VamosSpacing.md),
              ],

              // Loading indicator
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: VamosSpacing.md),
                  child: CircularProgressIndicator(),
                ),

              // Terms note
              Text(
                'Al continuar aceptás los términos de uso.',
                style: VamosTypography.caption.copyWith(
                  color: VamosColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: VamosSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains('sign-in-cancelled') || msg.contains('canceled')) {
      return 'El inicio de sesión fue cancelado.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Sin conexión. Revisá tu red e intentá de nuevo.';
    }
    return 'No se pudo iniciar sesión. Intentá de nuevo.';
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: icon,
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: VamosColors.text,
          side: const BorderSide(color: VamosColors.border),
          padding: const EdgeInsets.symmetric(vertical: VamosSpacing.md),
          textStyle: VamosTypography.titleMedium,
          shape: const RoundedRectangleBorder(
            borderRadius: VamosRadius.brFull,
          ),
        ),
      ),
    );
  }
}

/// Minimal Google "G" icon built with a Text widget to avoid adding
/// an external asset or package dependency.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontFamily: VamosTypography.fontDisplay,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: VamosColors.sol500,
      ),
    );
  }
}
