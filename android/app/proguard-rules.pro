# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your application classes
-keep class com.myflux.idea_bank.** { *; }

# Suppress warnings for common library issues
-dontwarn io.flutter.embedding.**
-dontwarn kotlin.**
