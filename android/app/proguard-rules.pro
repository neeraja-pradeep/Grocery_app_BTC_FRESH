# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# ========== Flutter Core Rules ==========
# Keep Flutter embedding classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Google Play Core (required by Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Firebase Crashlytics (if used)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ========== Razorpay Rules ==========
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

# ========== Networking Libraries ==========
# OkHttp (used by Razorpay and Dio)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Retrofit (if used)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# ========== JSON/Serialization ==========
# Gson (used by Razorpay)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepattributes Signature

# Keep generic signature of classes (needed for Freezed/JsonSerializable)
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# ========== Google Services ==========
# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

# ========== Keep All Native Methods ==========
-keepclasseswithmembernames class * {
    native <methods>;
}

# ========== Keep Enums ==========
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ========== Keep Parcelables ==========
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ========== Keep Serializable ==========
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ========== Remove Logging in Release ==========
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# ========== General Rules ==========
-keepattributes EnclosingMethod
-keepattributes InnerClasses
