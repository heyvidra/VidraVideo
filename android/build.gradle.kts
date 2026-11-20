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
}
// Plugins written before AGP 8 declare their package in the manifest and no
// `namespace`, and compile against an SDK today's androidx refuses
// (auto_orientation, via vidra_player). Give those their Gradle group as the
// namespace and a floor on compileSdk. Registered before the block below so it runs ahead of AGP's
// own afterEvaluate, which is where the missing namespace is fatal.
subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.let {
            if (it.namespace == null) it.namespace = project.group.toString()
            if ((it.compileSdk ?: 0) < 36) it.compileSdk = 36
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
