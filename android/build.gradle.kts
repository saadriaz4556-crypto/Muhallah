plugins {
    // Kotlin version (Using original 2.1.0 now that maps crash is avoided)
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false

    // Remove the version numbers here. Let Flutter/Gradle manage it.
    id("com.android.application") apply false
    id("com.android.library") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}