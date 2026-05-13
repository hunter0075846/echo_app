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

    def flutterVersion = flutter.rootProject.file("pubspec.yaml").text
def versionMatch = flutterVersion =~ /version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)/
def major = versionMatch[0][1].toInteger()
def minor = versionMatch[0][2].toInteger()
def patch = versionMatch[0][3].toInteger()
def build = versionMatch[0][4].toInteger()

defaultConfig {
        applicationId = "com.example.echo_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = major * 10000 + minor * 100 + patch * 10 + build
        versionName = "${major}.${minor}.${patch}+${build}"
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
