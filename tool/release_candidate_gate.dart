import 'dart:io';

class GateResult {
  final String id;
  final String title;
  final bool passed;
  final bool warning;
  final String detail;

  const GateResult.pass(this.id, this.title, this.detail)
      : passed = true,
        warning = false;

  const GateResult.warn(this.id, this.title, this.detail)
      : passed = true,
        warning = true;

  const GateResult.fail(this.id, this.title, this.detail)
      : passed = false,
        warning = false;
}

Future<void> main(List<String> args) async {
  final strict = args.contains('--strict');
  final results = <GateResult>[
    _checkFileExists('.github/workflows/ci.yml', 'ci_workflow', 'Flutter Android CI workflow'),
    _checkFileExists('pubspec.yaml', 'pubspec', 'Flutter pubspec'),
    _checkFileExists('analysis_options.yaml', 'analysis_options', 'Analyzer configuration'),
    _checkFileExists('.env', 'env_asset', 'Bundled environment asset'),
    _checkFileExists('android/app/build.gradle.kts', 'android_build', 'Android Gradle build file'),
    _checkFileExists('android/app/proguard-rules.pro', 'proguard', 'Android ProGuard rules'),
    _checkFileExists('lib/domain/export/export_state_machine.dart', 'export_state_machine', 'Strict export state machine'),
    _checkFileExists('lib/domain/export/device_capability_profile.dart', 'adaptive_export_profile', 'Adaptive export profile model'),
    _checkFileExists('lib/presentation/screens/pro/pro_control_center_screen.dart', 'pro_control_center', 'Pro export/proxy/cache panels'),
    _checkFileExists('docs/architecture/device_capability_profiler_adaptive_export.md', 'device_capability_docs', 'Device capability architecture docs'),
    _checkFileExists('docs/architecture/pro_export_proxy_cache_panels.md', 'pro_panel_docs', 'Pro panel architecture docs'),
    _checkPubspecVersion(),
    _checkEnvAsset(),
    _checkAndroidBuild(),
    _checkWorkflowCommands(),
    _checkNoDebugSecretsCommitted(),
  ];

  final failures = results.where((result) => !result.passed).toList();
  final warnings = results.where((result) => result.warning).toList();

  stdout.writeln('Release Candidate Gate');
  stdout.writeln('======================');
  for (final result in results) {
    final marker = !result.passed ? 'FAIL' : result.warning ? 'WARN' : 'PASS';
    stdout.writeln('[$marker] ${result.title} — ${result.detail}');
  }
  stdout.writeln('');
  stdout.writeln('Summary: ${results.length - failures.length}/${results.length} passed, ${warnings.length} warning(s).');

  if (failures.isNotEmpty || (strict && warnings.isNotEmpty)) {
    stderr.writeln('Release candidate gate failed.');
    exitCode = 1;
  }
}

GateResult _checkFileExists(String path, String id, String title) {
  final file = File(path);
  if (file.existsSync()) return GateResult.pass(id, title, '$path exists');
  return GateResult.fail(id, title, '$path is missing');
}

GateResult _checkPubspecVersion() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return const GateResult.fail('pubspec_version', 'App version', 'pubspec.yaml is missing');
  final text = file.readAsStringSync();
  final match = RegExp(r'^version:\s*([^\s]+)', multiLine: true).firstMatch(text);
  final version = match?.group(1);
  if (version == null || version.trim().isEmpty) {
    return const GateResult.fail('pubspec_version', 'App version', 'No version field found');
  }
  if (version.startsWith('0.0.0')) {
    return GateResult.warn('pubspec_version', 'App version', 'Version is still $version');
  }
  return GateResult.pass('pubspec_version', 'App version', version);
}

GateResult _checkEnvAsset() {
  final file = File('.env');
  if (!file.existsSync()) return const GateResult.fail('env_asset', 'Environment asset', '.env is missing but pubspec includes it as an asset');
  final text = file.readAsStringSync();
  final hasUrl = RegExp(r'^SUPABASE_URL=\S+', multiLine: true).hasMatch(text);
  final hasAnon = RegExp(r'^SUPABASE_ANON_KEY=\S+', multiLine: true).hasMatch(text);
  if (!hasUrl || !hasAnon) {
    return const GateResult.fail('env_asset', 'Environment asset', 'SUPABASE_URL or SUPABASE_ANON_KEY is missing');
  }
  return const GateResult.pass('env_asset', 'Environment asset', 'Supabase public config keys exist');
}

GateResult _checkAndroidBuild() {
  final file = File('android/app/build.gradle.kts');
  if (!file.existsSync()) return const GateResult.fail('android_build', 'Android build config', 'build.gradle.kts is missing');
  final text = file.readAsStringSync();
  final hasFlavors = text.contains('create("dev")') && text.contains('create("staging")') && text.contains('create("prod")');
  final hasRelease = text.contains('release {') && text.contains('isMinifyEnabled = true') && text.contains('isShrinkResources = true');
  final hasSigningFallback = text.contains('key.properties') && text.contains('signingConfigs.getByName("debug")');
  if (!hasFlavors) return const GateResult.fail('android_build', 'Android build config', 'dev/staging/prod flavors are not all configured');
  if (!hasRelease) return const GateResult.fail('android_build', 'Android build config', 'release minify/shrink config is missing');
  if (!hasSigningFallback) return const GateResult.warn('android_build', 'Android build config', 'Signing fallback was not detected');
  return const GateResult.pass('android_build', 'Android build config', 'Flavors, release shrinker, and signing fallback configured');
}

GateResult _checkWorkflowCommands() {
  final file = File('.github/workflows/ci.yml');
  if (!file.existsSync()) return const GateResult.fail('workflow_commands', 'CI commands', 'CI workflow is missing');
  final text = file.readAsStringSync();
  final required = <String>[
    'flutter pub get',
    'dart run build_runner build --delete-conflicting-outputs',
    'dart format --set-exit-if-changed lib test',
    'flutter analyze',
    'flutter test',
    'flutter build apk --debug --flavor dev',
    'flutter build apk --debug --flavor staging',
  ];
  final missing = required.where((command) => !text.contains(command)).toList();
  if (missing.isNotEmpty) {
    return GateResult.fail('workflow_commands', 'CI commands', 'Missing: ${missing.join(', ')}');
  }
  return const GateResult.pass('workflow_commands', 'CI commands', 'Analyze, test, codegen, and Android builds are present');
}

GateResult _checkNoDebugSecretsCommitted() {
  final riskyFiles = <String>[
    'android/key.properties',
    'android/app/upload-keystore.jks',
    'android/app/release.keystore',
  ];
  final present = riskyFiles.where((path) => File(path).existsSync()).toList();
  if (present.isNotEmpty) {
    return GateResult.fail('release_secrets', 'Release secrets', 'Do not commit release signing files: ${present.join(', ')}');
  }
  return const GateResult.pass('release_secrets', 'Release secrets', 'No obvious release signing files are committed');
}
