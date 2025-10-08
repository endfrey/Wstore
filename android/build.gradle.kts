// android/build.gradle.kts (Project-level)

plugins {
    // Google Services plugin สำหรับใช้ใน module
    id("com.google.gms.google-services") version "4.4.3" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ตั้งค่า build directory ใหม่
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

// ตั้งค่า build directory สำหรับ subprojects
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// ให้ subprojects ประเมิน module :app ก่อน
subprojects {
    project.evaluationDependsOn(":app")
}

// Task สำหรับ clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
