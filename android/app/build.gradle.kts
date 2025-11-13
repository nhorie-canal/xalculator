import java.util.Properties
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "jp.spheres.xalculator"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "jp.spheres.xalculator"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties.getProperty("keyAlias")
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword")
            val storeFileProp = keystoreProperties.getProperty("storeFile")
            val storePasswordProp = keystoreProperties.getProperty("storePassword")

            if (!storeFileProp.isNullOrEmpty()) {
                storeFile = file(storeFileProp)
            }
            if (!keyAliasProp.isNullOrEmpty()) keyAlias = keyAliasProp
            if (!keyPasswordProp.isNullOrEmpty()) keyPassword = keyPasswordProp
            if (!storePasswordProp.isNullOrEmpty()) storePassword = storePasswordProp
           
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders.putAll(
                mapOf(
                    "admobAppId" to "ca-app-pub-9967376970047175~4651465566"
                )
            )
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders.putAll(
                mapOf(
                    "admobAppId" to "ca-app-pub-9967376970047175~4651465566"
                )
            )
        }
    }
}

flutter {
    source = "../.."
}
