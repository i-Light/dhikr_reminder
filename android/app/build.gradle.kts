import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (git-ignored), written by
// scripts/create_upload_key.ps1:
//   storeFile=upload-keystore.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
// Without it a release build FAILS, so a build that cannot go to a store is
// never made by accident. To make one on purpose (a debug-signed release for a
// test phone, or the unsigned APK the F-Droid style stores want), pass
// the environment variable ALLOW_UNSIGNED=true (flutter build does not forward
// -P flags), or allowUnsigned=true in ~/.gradle/gradle.properties. Our own
// scripts never do.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProperties.containsKey("storeFile")
val allowUnsigned = providers.gradleProperty("allowUnsigned").orNull == "true" ||
    System.getenv("ALLOW_UNSIGNED") == "true"

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { task ->
        task.project == project &&
            task.name.endsWith("Release") &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle") ||
                task.name.startsWith("package"))
    }
    if (buildsRelease && !hasReleaseKey && !allowUnsigned) {
        throw GradleException(
            "android/key.properties is missing, so this release build would be " +
                "signed with the debug key and could not go to a store. Run " +
                "scripts/create_upload_key.ps1, or set ALLOW_UNSIGNED=true " +
                "if a debug-signed build is what you want.",
        )
    }
}

android {
    namespace = "com.gratovo.dhikr_reminder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The Play Store identity of the app. It can never change once the app
        // is published.
        applicationId = "com.gratovo.dhikr_reminder"
        // Android 8.0 at least: the reminder card is a foreground service
        // drawing a TYPE_APPLICATION_OVERLAY window, and notification channels
        // are used throughout; neither exists below it.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    packaging {
        jniLibs {
            // Keeps libflutter.so and libapp.so compressed inside the APK
            // instead of stored raw for mmap: the file is about half the size.
            // The phone unpacks them on install, so it uses more storage after
            // installing; the download and the APK on disk are much smaller.
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // Only reached with allowUnsigned (see the check above).
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // The reminder plan's arithmetic is tested on a plain JVM:
    //   cd android; .\gradlew :app:testDebugUnitTest
    testImplementation("junit:junit:4.13.2")
}

flutter {
    source = "../.."
}
