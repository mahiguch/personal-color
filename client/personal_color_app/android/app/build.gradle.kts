import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties for signing
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.personalcolor.personal_color_app"
    compileSdk = 36  // Android 14 (API Level 36)
    ndkVersion = "27.0.12077973"  // Required for plugins compatibility

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Personal Color Diagnosis App - Android Application ID
        applicationId = "com.personalcolor.personal_color_app"
        // Android 13+ support as specified in design document
        minSdk = 33  // Android 13 (API Level 33)
        targetSdk = 36  // Android 14 (API Level 36)
        versionCode = 1
        versionName = "1.0.0"
        
        // Test runner for instrumented tests
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        // Vector drawable support for older devices
        vectorDrawables.useSupportLibrary = true
    }

    // Signing configurations
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Use debug signing for now (replace with release signing for production)
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // App Bundle configuration for Google Play Store
    bundle {
        language {
            enableSplit = false  // Japanese only, no language splitting
        }
        density {
            enableSplit = true   // Enable density-based splits for smaller downloads
        }
        abi {
            enableSplit = true   // Enable architecture-based splits
        }
    }
}

flutter {
    source = "../.."
}
