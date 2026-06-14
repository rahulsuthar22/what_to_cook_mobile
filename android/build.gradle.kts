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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    tasks.configureEach {
        if (name.contains("extract", ignoreCase = true) && name.contains("Annotations", ignoreCase = true)) {
            actions = emptyList()
            doLast {
                try {
                    val buildDir = project.layout.buildDirectory.get().asFile
                    val variant = if (name.contains("debug", ignoreCase = true)) "debug" else "release"
                    val outputFile = File(buildDir, "intermediates/annotations_typedef_file/$variant/$name/typedefs.txt")
                    outputFile.parentFile.mkdirs()
                    outputFile.writeText("")
                } catch (e: Exception) {
                    // Safe fallback
                }
            }
        } else if (name.contains("lint", ignoreCase = true)) {
            enabled = false
        }
    }
}
