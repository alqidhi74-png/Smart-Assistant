buildscript {
    val kotlin_version by extra("1.8.10")

    repositories {
        google()
        mavenCentral()
    }

    dependencies {

        classpath("com.google.gms:google-services:4.4.4")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")

subprojects {
    buildDir = file("${rootProject.buildDir}/${name}")
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}