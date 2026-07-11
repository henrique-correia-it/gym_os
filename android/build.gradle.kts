allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Isar 3 still exposes the legacy Android extension and otherwise builds
    // its library with an SDK too old to resolve framework attributes such as
    // android:attr/lStar. Keep this compatibility override until Isar is
    // upgraded to a version that declares a modern compile SDK itself.
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            extensions.getByType<com.android.build.gradle.BaseExtension>().apply {
                compileSdkVersion(36)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
