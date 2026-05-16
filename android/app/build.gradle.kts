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

    // 签名配置
    signingConfigs {
        create("release") {
            // 从环境变量或本地文件读取签名信息
            val keystorePath = System.getenv("KEYSTORE_PATH") ?: "release-keystore.jks"
            val keystorePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            val keyAlias = System.getenv("KEY_ALIAS") ?: "release"
            val keyPassword = System.getenv("KEY_PASSWORD") ?: ""

            storeFile = file(keystorePath)
            storePassword = keystorePassword
            this.keyAlias = keyAlias
            this.keyPassword = keyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
