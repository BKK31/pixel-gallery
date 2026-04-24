plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.devtools.ksp")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.dagger.hilt.android")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.pixel.gallery"
    compileSdk = 35

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.pixel.gallery"
        minSdk = 26
        targetSdk = 35
        versionCode = 18
        versionName = "3.2.1"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = keystoreProperties["keyPassword"] as String? ?: System.getenv("KEY_PASSWORD")
            storePassword = keystoreProperties["storePassword"] as String? ?: System.getenv("STORE_PASSWORD")
            
            val storeFileProp = keystoreProperties["storeFile"] as String?
            if (storeFileProp != null) {
                storeFile = rootProject.file(storeFileProp)
            } else {
                val storeFileEnv = System.getenv("STORE_FILE")
                if (storeFileEnv != null) {
                    storeFile = rootProject.file(storeFileEnv)
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            if (releaseConfig.storeFile != null && releaseConfig.storeFile!!.exists()) {
                signingConfig = releaseConfig
            } else {
                signingConfig = signingConfigs.getByName("debug")
                println("Release keystore not found; falling back to debug signing.")
            }
        }
    }

    buildFeatures {
        compose = true
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs (for IzzyOnDroid/F-Droid)
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles (for Google Play)
        includeInBundle = false
    }

    packaging {
        jniLibs {
            // Native libraries are stored uncompressed in the APK (since Android 6.0). 
            // Setting this to true forces compression, reducing APK size.
            useLegacyPackaging = true
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Compose
    val composeBom = platform("androidx.compose:compose-bom:2025.02.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3:1.5.0-alpha17")
    implementation("androidx.compose.material3:material3-adaptive-navigation-suite")
    implementation("androidx.compose.material:material-icons-extended")
    
    // Core & Lifecycle
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    
    // Room
    val roomVersion = "2.6.1"
    implementation("androidx.room:room-runtime:$roomVersion")
    implementation("androidx.room:room-ktx:$roomVersion")
    ksp("androidx.room:room-compiler:$roomVersion")

    // Hilt
    val hiltVersion = "2.55"
    implementation("com.google.dagger:hilt-android:$hiltVersion")
    ksp("com.google.dagger:hilt-android-compiler:$hiltVersion")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.1.2")

    // Media3 (ExoPlayer)
    val media3Version = "1.5.1"
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-ui:$media3Version")
    implementation("androidx.media3:media3-common:$media3Version")

    // Biometric
    implementation("androidx.biometric:biometric:1.2.0-alpha05")
    
    // Utilities
    implementation("com.commonsware.cwac:document:0.5.0")
    implementation("com.drewnoakes:metadata-extractor:2.19.0")
    implementation("androidx.exifinterface:exifinterface:1.3.7")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.1")

    // Image loading
    implementation("com.github.bumptech.glide:glide:4.16.0")
    implementation("com.github.bumptech.glide:compose:1.0.0-beta01")
    ksp("com.github.bumptech.glide:ksp:4.16.0")
    implementation("me.saket.telephoto:zoomable-image-glide:0.14.0")
    
    // Other formats
    implementation("com.github.deckerst:androidsvg:c7e58e8e59")
    implementation("com.github.deckerst:Android-TiffBitmapFactory:424b18a4ae")

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
