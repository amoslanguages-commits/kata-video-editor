import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';
import 'package:nle_editor/presentation/screens/onboarding/app_start_gate.dart';
import 'package:nle_editor/presentation/widgets/errors/app_error_listener.dart';

class NleEditorApp extends ConsumerWidget {
  const NleEditorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      theme: AppTheme.darkTheme,
      builder: (context, child) => AppErrorListener(child: child!),
      home: const AppStartGate(),
    );
  }
}

