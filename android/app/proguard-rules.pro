# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Hive adapters
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Prevent stripping of annotations used by Gson/JSON serialization
-keepattributes *Annotation*
