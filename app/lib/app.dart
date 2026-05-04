import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/core/router/app_router.dart';
import 'package:vamos/core/theme/vamos_theme.dart';

/// App root.
///
/// Wires [GoRouter] (via [routerProvider]) and [VamosTheme].
/// [ProviderScope] is set up in [main.dart] / [main_dev.dart].
class VamosApp extends ConsumerWidget {
  const VamosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vamos',
      debugShowCheckedModeBanner: false,
      theme: VamosTheme.light,
      darkTheme: VamosTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
