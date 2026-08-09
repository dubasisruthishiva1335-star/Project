buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.buildscript.repositories.forEach { repo ->
        if (repo.name.contains("jcenter", ignoreCase = true)) {
            project.buildscript.repositories.remove(repo)
        }
    }
    project.repositories.forEach { repo ->
        if (repo.name.contains("jcenter", ignoreCase = true)) {
            project.repositories.remove(repo)
        }
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

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
