import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseAppLabel = "FlorysDiaries"
val debugAppLabel = "FlorysDiaries DEV"

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("Release", ignoreCase = true)
}

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { input ->
        keystoreProperties.load(input)
    }
}

fun releaseProperty(name: String): String? {
    val value = keystoreProperties.getProperty(name)?.trim()
    if (value.isNullOrEmpty() || value.startsWith("DEIN_") || value.startsWith("YOUR_")) {
        return null
    }
    return value
}

val storePasswordValue = releaseProperty("storePassword")
val keyPasswordValue = releaseProperty("keyPassword")
val keyAliasValue = releaseProperty("keyAlias")
val storeFileValue = releaseProperty("storeFile")
val releaseStoreFile = storeFileValue?.let { value -> rootProject.file(value) }

val hasCompleteReleaseSigning =
    storePasswordValue != null &&
        keyPasswordValue != null &&
        keyAliasValue != null &&
        releaseStoreFile != null &&
        releaseStoreFile.exists()

if (releaseTaskRequested && !hasCompleteReleaseSigning) {
    throw GradleException(
        "Release-Signierung ist unvollständig. Prüfe android/key.properties " +
            "und den dort angegebenen Keystore-Pfad.",
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
        manifestPlaceholders["appLabel"] = releaseAppLabel
    }

    signingConfigs {
        if (hasCompleteReleaseSigning) {
            create("release") {
                storePassword = storePasswordValue
                keyPassword = keyPasswordValue
                keyAlias = keyAliasValue
                storeFile = releaseStoreFile
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = debugAppLabel
        }

        release {
            manifestPlaceholders["appLabel"] = releaseAppLabel
            if (hasCompleteReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
