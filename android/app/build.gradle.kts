import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("Release", ignoreCase = true)
}

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { input ->
        keystoreProperties.load(input)
    }
} else if (releaseTaskRequested) {
    throw GradleException(
        "Release-Signierung fehlt: android/key.properties wurde nicht gefunden.",
    )
}

android {
    namespace = "com.florysdiaries.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.florysdiaries.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "FlorysDiaries"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                val storePasswordValue =
                    keystoreProperties.getProperty("storePassword")
                        ?: throw GradleException(
                            "storePassword fehlt in android/key.properties.",
                        )
                val keyPasswordValue =
                    keystoreProperties.getProperty("keyPassword")
                        ?: throw GradleException(
                            "keyPassword fehlt in android/key.properties.",
                        )
                val keyAliasValue =
                    keystoreProperties.getProperty("keyAlias")
                        ?: throw GradleException(
                            "keyAlias fehlt in android/key.properties.",
                        )
                val storeFileValue =
                    keystoreProperties.getProperty("storeFile")
                        ?: throw GradleException(
                            "storeFile fehlt in android/key.properties.",
                        )

                storePassword = storePasswordValue
                keyPassword = keyPasswordValue
                keyAlias = keyAliasValue
                storeFile = file(storeFileValue)
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = "FlorysDiaries DEV"
        }

        release {
            manifestPlaceholders["appLabel"] = "FlorysDiaries"
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
