plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // Flutter plugin must come after Android + Kotlin
    id("dev.flutter.flutter-gradle-plugin")

    // Google Services plugin REMOVED

}

android {
    namespace = "Bharat.shop"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "Bharat.shop"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase and Google Sign In Dependencies REMOVED
}

flutter {
    source = "../.."
}
