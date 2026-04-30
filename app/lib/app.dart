import 'package:flutter/material.dart';

import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';

/// Raíz de la app. Configura `MaterialApp` con el theme tokenizado.
///
/// TODO cuando se sume Riverpod: envolver el `runApp` en `ProviderScope`.
/// TODO cuando se sume go_router: reemplazar `home` por `routerConfig`.
class VamosApp extends StatelessWidget {
  const VamosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vamos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // TODO: dark theme se activa cuando lo decida el diseño.
      // darkTheme: AppTheme.dark(),
      home: const _HomePlaceholder(),
    );
  }
}

/// Placeholder hasta que se implemente F1.1 (Mis Viajes).
/// Sirve también como ejemplo del uso correcto de tokens.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vamos',
                  style: text.displayMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Acá no hay nada todavía.',
                  style: text.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'F1.1 — Mis Viajes va acá.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
