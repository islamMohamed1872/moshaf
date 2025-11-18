import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val envFile = rootProject.file("../.env")
var googleMapsApiKey = ""

if (envFile.exists()) {
    envFile.forEachLine { line ->
        if (line.startsWith("GOOGLE_MAPS_API_KEY=")) {
            googleMapsApiKey = line.split("=")[1].trim()
        }
    }
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.afaqalspl.moshaf"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true

    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.afaqalspl.moshaf"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        // ✅ Kotlin style manifest placeholders
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
//            signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    sourceSets {
        getByName("main") {
            res.srcDirs("src/main/res")
        }
    }
    androidResources {
        noCompress += listOf("mp3")
    }
}

kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}
dependencies {
    // ✅ Add this line so desugaring actually works
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    val exoplayerVersion = "2.19.1"
    implementation("com.google.android.exoplayer:exoplayer-core:${exoplayerVersion}")
    implementation("com.google.android.exoplayer:exoplayer-dash:${exoplayerVersion}")
    implementation("com.google.android.exoplayer:exoplayer-hls:${exoplayerVersion}")
    implementation("com.google.android.exoplayer:exoplayer-smoothstreaming:${exoplayerVersion}")
}