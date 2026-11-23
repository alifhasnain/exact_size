import com.android.build.api.artifact.SingleArtifact
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.exactsize.exact_size"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.exactsize.exact_size"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28 // ADR-001: Android 9 minimum (HEIC decode on all supported devices)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// FEAT-001 (ADR-006): photo picker and camera contracts, FileProvider. Versions from the
// gate G1 record (docs/features/FEAT-001-pick-image/t01/spike_record.md, item e).
dependencies {
    implementation("androidx.activity:activity:1.10.1")
    implementation("androidx.core:core:1.16.0")
}

// FEAT-001-T09 (FR-18, AC-6.4, ADR-006): fail the release build if the merged manifest asks for
// camera or media permissions, exposes the camera FileProvider, widens its paths, or loses the
// IMAGE_CAPTURE query. It only reports; it never strips entries with tools:node="remove".
abstract class CheckMergedManifest : DefaultTask() {
    @get:InputFile abstract val manifest: RegularFileProperty
    @get:InputFile abstract val cameraPaths: RegularFileProperty
    @get:Input abstract val authority: Property<String>

    @TaskAction
    fun check() {
        val android = "http://schemas.android.com/apk/res/android"
        fun parse(f: File) = DocumentBuilderFactory.newInstance().apply { isNamespaceAware = true }
            .newDocumentBuilder().parse(f).documentElement
        fun Element.all(tag: String) = getElementsByTagName(tag).let { l -> (0 until l.length).map { l.item(it) as Element } }
        fun Element.a(name: String) = getAttributeNS(android, name)

        val root = parse(manifest.get().asFile)
        val problems = mutableListOf<String>()

        val banned = setOf("android.permission.CAMERA", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.ACCESS_MEDIA_LOCATION")
        for (tag in listOf("uses-permission", "uses-permission-sdk-23")) {
            for (p in root.all(tag).map { it.a("name") }) {
                if (p in banned || p.startsWith("android.permission.READ_MEDIA_")) {
                    problems += "Banned permission $p in the merged manifest (FEAT-001 FR-18). Find the dependency that adds it; do not strip it with tools:node=\"remove\"."
                }
            }
        }

        val ours = root.all("provider").filter { p -> p.a("authorities").split(';').any { it.trim() == authority.get() } }
        if (ours.isEmpty()) problems += "No FileProvider with authority ${authority.get()} in the merged manifest."
        for (p in ours) {
            if (p.a("exported") != "false") problems += "FileProvider ${authority.get()} must have android:exported=\"false\" (found \"${p.a("exported")}\")."
            val paths = p.all("meta-data").filter { it.a("name") == "android.support.FILE_PROVIDER_PATHS" }.map { it.a("resource") }
            if (paths != listOf("@xml/camera_paths")) problems += "FileProvider ${authority.get()} must use only @xml/camera_paths (found $paths)."
        }

        val entries = parse(cameraPaths.get().asFile).childNodes.let { l -> (0 until l.length).map { l.item(it) }.filterIsInstance<Element>() }
        val onlyCamera = entries.size == 1 && entries[0].tagName == "cache-path" && entries[0].getAttribute("path") == "camera/"
        if (!onlyCamera) problems += "camera_paths.xml must hold exactly one <cache-path path=\"camera/\"/> (found ${entries.map { "<${it.tagName} path=\"${it.getAttribute("path")}\">" }})."

        val capture = root.all("queries").flatMap { it.all("action") }.any { it.a("name") == "android.media.action.IMAGE_CAPTURE" }
        if (!capture) problems += "The <queries> entry for android.media.action.IMAGE_CAPTURE is missing (FEAT-001 FR-5)."

        // FEAT-001-T24 (FR-20, AC-8.3): only the launcher and the single-image share target are exported.
        for (act in root.all("activity").filter { it.a("exported") == "true" }) {
            val filters = act.all("intent-filter").map { f -> f.all("action").map { it.a("name") }.toSet() to f.all("data").map { it.a("mimeType") }.toSet() }
            val allowed = when (act.a("name").substringAfterLast('.')) {
                "MainActivity" -> filters == listOf(setOf("android.intent.action.MAIN") to emptySet<String>())
                "ShareTargetActivity" -> filters == listOf(setOf("android.intent.action.SEND") to setOf("image/*"))
                else -> false
            }
            if (!allowed) problems += "Exported activity ${act.a("name")} with filters $filters is not allowed: only MainActivity (launcher) and ShareTargetActivity (one SEND image/* filter, no SEND_MULTIPLE) may be exported (FEAT-001 FR-20, AC-8.3)."
        }

        if (problems.isNotEmpty()) throw GradleException("checkMergedManifest failed:\n- " + problems.joinToString("\n- "))
        logger.lifecycle("checkMergedManifest: OK")
    }
}

androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        val check = tasks.register<CheckMergedManifest>("checkMergedManifest") {
            manifest.set(variant.artifacts.get(SingleArtifact.MERGED_MANIFEST))
            cameraPaths.set(layout.projectDirectory.file("src/main/res/xml/camera_paths.xml"))
            authority.set(variant.applicationId.map { "$it.camera" })
        }
        tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }.configureEach { dependsOn(check) }
    }
}
