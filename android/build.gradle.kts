allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    configurations.configureEach {
        resolutionStrategy.force(
            "androidx.activity:activity:1.8.1",
            "androidx.activity:activity-ktx:1.8.1",
            "androidx.fragment:fragment:1.7.1",
            "androidx.fragment:fragment-ktx:1.7.1",
            "androidx.savedstate:savedstate:1.2.1",
            "androidx.savedstate:savedstate-ktx:1.2.1",
        )
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
