import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VoiceRecordingPathService {
  const VoiceRecordingPathService();

  Future<String> createTakePath({
    required String projectId,
    required String takeId,
    required String extension,
  }) async {
    final dir = await getApplicationDocumentsDirectory();

    final voiceDir = Directory(
      p.join(
        dir.path,
        'projects',
        projectId,
        'voice_takes',
      ),
    );

    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }

    final safeExtension = extension.startsWith('.') ? extension.substring(1) : extension;

    return p.join(
      voiceDir.path,
      'take_$takeId.$safeExtension',
    );
  }

  Future<void> deleteFileIfExists(String localPath) async {
    final file = File(localPath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
