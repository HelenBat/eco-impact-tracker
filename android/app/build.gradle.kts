import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("Missing key.properties file at ${keystorePropertiesFile.absolutePath}")
}

val keyAliasValue = keystoreProperties["keyAlias"]?.toString()
    ?: throw GradleException("Missing keyAlias in key.properties")
val keyPasswordValue = keystoreProperties["keyPassword"]?.toString()
    ?: throw GradleException("Missing keyPassword in key.properties")
val storeFileValue = keystoreProperties["storeFile"]?.toString()
    ?: throw GradleException("Missing storeFile in key.properties")
val storePasswordValue = keystoreProperties["storePassword"]?.toString()
    ?: throw GradleException("Missing storePassword in key.properties")

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.helenbatu.ecoimpactapp"
    compileSdk = 34
    //ndkVersion = "27.0.12077973"


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.helenbatu.ecoimpactapp"
        minSdk = 22
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
            storeFile = file(storeFileValue)
            storePassword = storePasswordValue
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
