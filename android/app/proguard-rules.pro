# Stripe ProGuard rules
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.**
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.** { *; }

# Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core ProGuard rules
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
