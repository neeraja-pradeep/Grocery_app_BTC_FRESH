# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Keep Razorpay classes
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface
-keepattributes *Annotation*

-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

-optimizations !method/inlining/

-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Keep Razorpay payment success/failure methods
-keep class com.razorpay.PaymentResultListener {*;}
-keep class com.razorpay.PaymentData {*;}

# Keep all methods in Razorpay plugin
-keep class io.flutter.plugins.razorpay.** { *; }

# Keep Flutter Razorpay bridge
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# OkHttp (used by Razorpay)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Gson (used by Razorpay)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep data classes used in payment
-keep class * extends java.io.Serializable { *; }
