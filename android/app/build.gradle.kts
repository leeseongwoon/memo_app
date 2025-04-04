import java.util.Properties

// 이 변환 타입을 사용하면 컴파일러가 이것이 무엇인지 알 수 있습니다.
val flutterRoot = project.property("flutter.sdk")?.toString() ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
val flutterVersionCode = project.property("flutter.versionCode")?.toString()?.toIntOrNull() ?: 1
val flutterVersionName = project.property("flutter.versionName")?.toString() ?: "1.0"

/*
 * Copyright 2019-2023 The Android Open Source Project
 */

plugins {
    kotlin("android") version "1.9.21"
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.new_memo_app"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.new_memo_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = 19
        targetSdk = 34
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = ".."
}
