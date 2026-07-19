# ProGuard/R8 rules for the release build.

# --- google_mlkit_text_recognition ---
# Only the Latin text-recognition model is bundled with the app. The plugin
# still references the other language recognizers, which makes R8 fail with
# "Missing classes" during minifyReleaseWithR8. Silence those references and
# keep the ML Kit classes that are loaded reflectively.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# --- Flutter deferred components (Play Core) ---
# The Flutter engine references Play Core split-install classes even when
# deferred components are not used.
-dontwarn com.google.android.play.core.**

# --- Firebase / Google Sign-In ---
# Keep annotated model/serialization classes used via reflection.
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <methods>;
}
