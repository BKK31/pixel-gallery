plugins {
    id("com.android.application") version "8.9.1" apply false
    id("com.android.library") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.10" apply false
    id("com.google.dagger.hilt.android") version "2.55" apply false
    id("com.google.devtools.ksp") version "2.1.10-1.0.29" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.10" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://s3.amazonaws.com/repo.commonsware.com") }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
