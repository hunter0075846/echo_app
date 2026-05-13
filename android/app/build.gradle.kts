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
        // 版本号从 pubspec.yaml 读取
        val pubspecContent = flutter.rootProject.file("pubspec.yaml").readText()
        val versionRegex = Regex("version:\\s*(\\d+)\\.(\\d+)\\.(\\d+)\\+(\\d+)")
        val matchResult = versionRegex.find(pubspecContent)
        versionCode = if (matchResult != null) {
            val (major, minor, patch, build) = matchResult.destructured
            major.toInt() * 10000 + minor.toInt() * 100 + patch.toInt() * 10 + build.toInt()
        } else {
            1
        }
        versionName = if (matchResult != null) {
            val (major, minor, patch, build) = matchResult.destructured
            "$major.$minor.$patch+$build"
        } else {
            "1.0.0+1"
        }
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
