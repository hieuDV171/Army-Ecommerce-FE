plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.m25team.army_ecommerce"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.m25team.army_ecommerce"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    applicationVariants.all {
        val variantName = name
        val variantVersion = versionName
        outputs.forEach { output ->
            val castedOutput = output as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            
            // Lời khuyên: Nên dùng tiếng Việt KHÔNG DẤU để đặt tên file. 
            // Đặt tên có dấu (Sàn_Thương_Mại...) rất dễ gây lỗi hệ thống file khi tải lên Store hoặc máy chủ.
            castedOutput.outputFileName = "Sàn_Thương_Mại_Điện_Tử_Quân_Đội_${variantName}_v${variantVersion}.apk"
        }
    }

}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
