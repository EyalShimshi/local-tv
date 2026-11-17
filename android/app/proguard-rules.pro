# Keep file and line numbers in stack traces (crash reports); the mapping file decodes the names.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Web-page channels (Channel 12) report their player state through this bridge.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# jsoup's optional and build-time-only dependencies.
-dontwarn com.google.re2j.**
-dontwarn org.jspecify.annotations.**
