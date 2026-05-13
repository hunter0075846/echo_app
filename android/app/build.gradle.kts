plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.echo_app"
    compileSdk = 36
    buildToolsVersion = "34.0.0"
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.echo_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Flutter 会自动从 pubspec.yaml 读取版本号
        // versionCode 和 versionName 由 flutter.gradle 自动设置
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
