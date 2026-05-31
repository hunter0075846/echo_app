plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 从 pubspec.yaml 解析版本号（Kotlin DSL 不会自动注入）
val pubspec = rootProject.file("../pubspec.yaml").readText()
val versionMatch = Regex("""version:\s*([^\s+]+)\+(\d+)""").find(pubspec)
val flutterVersionName = versionMatch?.groupValues?.get(1) ?: "1.0.0"
val flutterVersionCode = versionMatch?.groupValues?.get(2)?.toInt() ?: 1

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
        minSdk = 23
        targetSdk = 36
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // 使用默认签名配置，不强制验证
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs {
            excludes += listOf("lib/x86_64/**", "lib/armeabi-v7a/**")
        }
    }
}

flutter {
    source = "../.."
}
