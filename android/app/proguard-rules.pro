# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Prevent obfuscation of Flutter engine
-dontwarn io.flutter.embedding.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Gson specific rules (if using Gson for JSON parsing)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes (adjust package name as needed)
-keep class com.example.monitoring_project.** { *; }

# OkHttp and Retrofit (if using for API calls)
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Flutter Secure Storage - Keep encryption classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Android Security & Crypto
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }
-dontwarn javax.crypto.**
-keep class java.security.** { *; }
-dontwarn java.security.**

# AndroidX Security Crypto (for EncryptedSharedPreferences)
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Prevent stripping of security-related classes
-keepclassmembers class * {
    @androidx.security.crypto.* <methods>;
}
