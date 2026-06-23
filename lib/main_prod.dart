import 'package:nle_editor/app/bootstrap.dart';
import 'package:nle_editor/core/config/app_environment.dart';

Future<void> main() async {
  await bootstrapApp(
    environment: AppEnvironment.production,
  );
}
