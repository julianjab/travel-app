import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                  color: colorScheme.onSurfaceVariant,
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
              if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                _SignInButton(
                  label: 'Continuar con Apple',
                  icon: Icon(
                    Icons.apple,
                    size: 22,
                    color: colorScheme.onSurface,
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
                Padding(
                  padding: const EdgeInsets.only(bottom: VamosSpacing.md),
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),

              // Terms note
              Text(
                'Al continuar aceptás los términos de uso.',
                style: VamosTypography.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: icon,
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
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
    return Text(
      'G',
      style: TextStyle(
        fontFamily: VamosTypography.fontDisplay,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
