plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.kapt")
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")
    id("androidx.room")
}

android {
    namespace = "io.nextsense.android.main.lucid"
    compileSdk = 34
    signingConfigs {
        getByName("debug") {
            storeFile = file("../debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        create("release") {
            // Need to add these values to your local gradle.properties file.
            storeFile = file(project.properties["RELEASE_STORE_FILE"].toString())
            keyAlias = project.properties["RELEASE_KEY_ALIAS"].toString()
            storePassword = project.properties["RELEASE_STORE_PASSWORD"].toString()
            keyPassword = project.properties["RELEASE_KEY_PASSWORD"].toString()
        }
    }
    defaultConfig {
        applicationId = "io.nextsense.android.main.lucid"
        minSdk = 30
        targetSdk = 33
        versionCode = 2
        versionName = "1.0.1"
        vectorDrawables {
            useSupportLibrary = true
        }

    }
    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
            )
        }
    }
    flavorDimensions += listOf("env")
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
        }

        create("prod") {
            dimension = "env"
            applicationIdSuffix = ".prod"
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.3"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    androidResources {
        noCompress += "tflite"
    }

    applicationVariants.all {
        addJavaSourceFoldersToModel(
            File(buildDir, "generated/ksp/$name/kotlin")
        )
    }

    room {
        schemaDirectory("$projectDir/scshemas/")
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-wearable:18.1.0")
    implementation(platform("androidx.compose:compose-bom:2023.08.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.wear.compose:compose-material:1.3.0")
    implementation("androidx.wear.compose:compose-foundation:1.3.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("androidx.compose.material:material-icons-extended:1.6.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("com.google.android.horologist:horologist-compose-layout:0.6.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    // Health Services
    implementation("androidx.lifecycle:lifecycle-service:2.7.0")
    // Used for permissions
    implementation("com.google.accompanist:accompanist-permissions:0.34.0")
    // Used to bridge between Futures and coroutines
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
    implementation("androidx.concurrent:concurrent-futures-ktx:1.1.0")
    implementation("com.google.guava:guava:31.0.1-jre")
    implementation("androidx.wear:wear-remote-interactions:1.0.0")
    implementation("androidx.wear:wear-phone-interactions:1.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    implementation("androidx.hilt:hilt-common:1.2.0")
    implementation("androidx.hilt:hilt-work:1.2.0")
    val roomVersion = "2.6.1"
    implementation("androidx.room:room-runtime:$roomVersion")
    annotationProcessor("androidx.room:room-compiler:$roomVersion")
    ksp("androidx.room:room-compiler:$roomVersion")
    implementation("androidx.room:room-ktx:$roomVersion")
    //TFLite dependencies
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-gpu:0.0.0-nightly")
    implementation("org.tensorflow:tensorflow-lite-support:0.3.1")
    //Wear on going
    implementation("androidx.wear:wear-ongoing:1.0.0")
    // Hilt
    implementation("com.google.dagger:hilt-android:2.50")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")
    // To use Kotlin annotation processing tool (kapt)
    kapt("com.google.dagger:hilt-android-compiler:2.50")
    kapt("androidx.hilt:hilt-compiler:1.2.0")
    // Work manager + Kotlin + coroutines
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    //destinations
    implementation("io.github.raamcosta.compose-destinations:core:1.9.63")
    ksp("io.github.raamcosta.compose-destinations:ksp:1.9.63")
    //GSON
    implementation("com.google.code.gson:gson:2.10")
    androidTestImplementation(platform("androidx.compose:compose-bom:2023.08.00"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}