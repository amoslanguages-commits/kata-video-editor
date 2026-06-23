class InternalTesterGuide {
  static const markdown = '''
# Internal Tester Guide

## Main Test Areas

1. Create a project
2. Import video, audio, and images
3. Add clips to timeline
4. Trim and move clips
5. Add text
6. Add transition
7. Apply premium preset
8. Generate proxy
9. Export with audio
10. Close app during editing and test recovery
11. Delete/rename source media and test reconnect
12. Clear cache and confirm originals are not deleted

## Report Bugs With

- device model
- Android/iOS version
- app version/build number
- project duration
- source media resolution
- steps to reproduce
- screenshot or screen recording
- export job error message

## Important Safety Checks

- Originals must never be deleted by cache cleanup.
- Production build must not show dev Pro unlock.
- Export should fail gracefully, not crash.
- Missing media should show reconnect UI.
- App should work offline for editing/export.
''';
}
