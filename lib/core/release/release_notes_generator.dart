class ReleaseNotesInput {
  final String version;
  final String buildNumber;
  final List<String> highlights;
  final List<String> fixes;
  final List<String> knownIssues;

  const ReleaseNotesInput({
    required this.version,
    required this.buildNumber,
    required this.highlights,
    required this.fixes,
    required this.knownIssues,
  });
}

class ReleaseNotesGenerator {
  String generateMarkdown(ReleaseNotesInput input) {
    final buffer = StringBuffer();

    buffer.writeln('# Kata ${input.version}+${input.buildNumber}');
    buffer.writeln();
    buffer.writeln('## Highlights');

    if (input.highlights.isEmpty) {
      buffer.writeln('- Initial internal release.');
    } else {
      for (final item in input.highlights) {
        buffer.writeln('- $item');
      }
    }

    buffer.writeln();
    buffer.writeln('## Fixes');

    if (input.fixes.isEmpty) {
      buffer.writeln('- No fixes listed.');
    } else {
      for (final item in input.fixes) {
        buffer.writeln('- $item');
      }
    }

    buffer.writeln();
    buffer.writeln('## Known Issues');

    if (input.knownIssues.isEmpty) {
      buffer.writeln('- No known issues listed.');
    } else {
      for (final item in input.knownIssues) {
        buffer.writeln('- $item');
      }
    }

    buffer.writeln();
    buffer.writeln('## Tester Focus');
    buffer.writeln('- Import videos, images, and audio.');
    buffer.writeln('- Test preview playback and timeline seeking.');
    buffer.writeln('- Export with text, transitions, effects, and audio.');
    buffer.writeln('- Test missing-media reconnect flow.');
    buffer.writeln('- Test low-storage and recovery flows.');

    return buffer.toString();
  }
}
