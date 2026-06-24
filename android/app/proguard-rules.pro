# Kata / NLE Editor release shrinker rules
# Keep this file present because android/app/build.gradle.kts references it for release builds.

# Flutter engine and embedding are normally handled by the Flutter Gradle plugin,
# but keeping the embedding is harmless and avoids aggressive shrinker edge cases.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }

# Keep app MethodChannel/EventChannel bridge entry points and native media models.
-keep class com.kata.videoeditor.nle.** { *; }
-keep class com.nle.editor.** { *; }

# Keep Android media codec classes referenced through platform APIs.
-keep class android.media.** { *; }

# Keep JSON constructors/fields where reflection or map-style payloads are used.
-keepattributes Signature
-keepattributes *Annotation*

# Drift/sqlite native libraries are packaged by Flutter/Gradle dependencies.
# No app-specific obfuscation exemptions are needed for Dart code because Dart is
# compiled separately by Flutter.
