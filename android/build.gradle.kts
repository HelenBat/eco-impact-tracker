allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// --- THE FIX IS HERE (Placed BEFORE evaluationDependsOn) ---
subprojects {
    afterEvaluate {
        // Look for the android extension (present in app and plugins)
        val android = extensions.findByName("android")
        // If found, force it to use SDK 34 to fix the lStar error
        if (android != null) {
            (android as? com.android.build.gradle.BaseExtension)?.compileSdkVersion(34)
        }
    }
}
// -----------------------------------------------------------

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}