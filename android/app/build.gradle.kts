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

// FEAT-001-T09 (FR-18, AC-6.4, ADR-006) and FEAT-007-T04 (FR-8, FR-18, NFR-5, ADR-007): fail the
// release build if the merged manifest asks for camera, media or broad storage permissions or an
// uncapped WRITE_EXTERNAL_STORAGE, exports a provider, widens or adds a FileProvider, or loses the
// IMAGE_CAPTURE query. It only reports; it never strips entries with tools:node="remove".
// Each run also self-tests: broken copies of the real manifest must each be refused.
// FEAT-016-T02 (FR-8, FR-11, NFR-5): every requested permission must be on a reviewed allow-list,
// and a marker file proves to CI that the task ran (non-verbose `flutter build` hides its log line).
// The task is registered for the release variant by name; a product-flavor change must rename it
// per variant and update the CI marker assertion.
abstract class CheckMergedManifest : DefaultTask() {
    @get:InputFile abstract val manifest: RegularFileProperty
    @get:InputFile abstract val cameraPaths: RegularFileProperty
    @get:InputFile abstract val sharePaths: RegularFileProperty
    @get:Input abstract val applicationId: Property<String>
    @get:OutputFile abstract val marker: RegularFileProperty

    private val followFr12 = "Follow FEAT-016 FR-12 (docs/features/FEAT-016-on-device-privacy/claims.md)."

    private val android = "http://schemas.android.com/apk/res/android"
    private fun parse(f: File) = DocumentBuilderFactory.newInstance().apply { isNamespaceAware = true }
        .newDocumentBuilder().parse(f).documentElement
    private fun Element.all(tag: String) = getElementsByTagName(tag).let { l -> (0 until l.length).map { l.item(it) as Element } }
    private fun Element.a(name: String) = getAttributeNS(android, name)
    private fun Element.children() = childNodes.let { l -> (0 until l.length).map { l.item(it) }.filterIsInstance<Element>() }
    private fun Element.authorities() = a("authorities").split(';').map { it.trim() }
    private fun Element.pathsResource() = all("meta-data").filter { it.a("name") == "android.support.FILE_PROVIDER_PATHS" }.map { it.a("resource") }

    private fun problems(root: Element, camera: Element, share: Element): List<String> {
        val id = applicationId.get()
        val problems = mutableListOf<String>()

        // FEAT-016 FR-8: the reviewed set of permissions (T01 H3: release APK, 2026-11-26).
        val reviewed = setOf("android.permission.WRITE_EXTERNAL_STORAGE", "$id.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION")
        val network = mapOf(
            "android.permission.INTERNET" to "lets the app use the network",
            "android.permission.ACCESS_NETWORK_STATE" to "reads the network state",
            "android.permission.ACCESS_WIFI_STATE" to "reads the Wi-Fi state",
            "com.google.android.gms.permission.AD_ID" to "reads the advertising ID",
        )
        val banned = setOf("android.permission.CAMERA", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.ACCESS_MEDIA_LOCATION",
            "android.permission.MANAGE_EXTERNAL_STORAGE")
        for (tag in listOf("uses-permission", "uses-permission-sdk-23")) {
            for (p in root.all(tag)) {
                val name = p.a("name")
                if (name in banned || name.startsWith("android.permission.READ_MEDIA_")) {
                    problems += "Banned permission $name in the merged manifest (FEAT-001 FR-18, FEAT-007 FR-8). Find the dependency that adds it; do not strip it with tools:node=\"remove\"."
                } else if (name in network) {
                    problems += "Permission $name ($tag) ${network[name]}: ExactSize never uses the network (FEAT-016 FR-8). Find the dependency that adds it; do not strip it with tools:node=\"remove\". $followFr12"
                } else if (name !in reviewed) {
                    problems += "Permission $name ($tag) is not on the reviewed list (FEAT-016 FR-8). $followFr12"
                }
                if (name == "android.permission.WRITE_EXTERNAL_STORAGE" && (p.a("maxSdkVersion").toIntOrNull() ?: Int.MAX_VALUE) > 28) {
                    problems += "WRITE_EXTERNAL_STORAGE must have android:maxSdkVersion=\"28\" or lower (found \"${p.a("maxSdkVersion")}\") (FEAT-007 FR-8)."
                }
            }
        }

        val providers = root.all("provider")
        for (p in providers.filter { it.a("exported") == "true" }) problems += "Provider ${p.a("authorities")} must not be exported (FEAT-007 NFR-5)."
        val expected = mapOf("$id.camera" to "@xml/camera_paths", "$id.share" to "@xml/share_paths")
        for ((auth, res) in expected) {
            val found = providers.filter { auth in it.authorities() }
            if (found.size != 1) problems += "Expected one FileProvider with authority $auth (found ${found.size})."
            for (p in found) {
                if (p.a("exported") != "false") problems += "FileProvider $auth must have android:exported=\"false\" (found \"${p.a("exported")}\")."
                if (p.pathsResource() != listOf(res)) problems += "FileProvider $auth must use only $res (found ${p.pathsResource()})."
            }
        }
        for (p in providers.filter { it.pathsResource().isNotEmpty() && it.authorities().none { a -> a in expected } }) {
            problems += "Unexpected FileProvider ${p.a("authorities")}: only the camera and share FileProviders may exist (FEAT-007 FR-18)."
        }

        fun onlyPath(r: Element, path: String) = r.children().let { it.size == 1 && it[0].tagName == "cache-path" && it[0].getAttribute("path") == path }
        fun describe(r: Element) = r.children().map { "<${it.tagName} path=\"${it.getAttribute("path")}\">" }
        if (!onlyPath(camera, "camera/")) problems += "camera_paths.xml must hold exactly one <cache-path path=\"camera/\"/> (found ${describe(camera)})."
        if (!onlyPath(share, "exactsize_share/")) problems += "share_paths.xml must hold exactly one <cache-path path=\"exactsize_share/\"/> (found ${describe(share)})."

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
        return problems
    }

    @TaskAction
    fun check() {
        val problems = problems(parse(manifest.get().asFile), parse(cameraPaths.get().asFile), parse(sharePaths.get().asFile)).toMutableList()

        // Self-test (FEAT-007-T04, FEAT-016-T02): each broken copy must be refused; a permission
        // mutation must be refused with a message that names the permission and points to FR-12.
        fun write(r: Element) = r.all("uses-permission").first { it.a("name") == "android.permission.WRITE_EXTERNAL_STORAGE" }
        fun share(r: Element) = r.all("provider").first { "${applicationId.get()}.share" in it.authorities() }
        fun ask(r: Element, tag: String, name: String) =
            r.appendChild(r.ownerDocument.createElement(tag).also { it.setAttributeNS(android, "android:name", name) })
        val namedIn = mapOf(
            "INTERNET added" to "android.permission.INTERNET",
            "ACCESS_NETWORK_STATE as uses-permission-sdk-23" to "android.permission.ACCESS_NETWORK_STATE",
            "AD_ID added" to "com.google.android.gms.permission.AD_ID",
            "unknown permission added" to "[PLACEHOLDER].permission.UNREVIEWED",
        )
        val mutations: List<Pair<String, (Element, Element) -> Unit>> = listOf(
            "WRITE uncapped" to { r, _ -> write(r).removeAttributeNS(android, "maxSdkVersion") },
            "WRITE capped at 29" to { r, _ -> write(r).setAttributeNS(android, "android:maxSdkVersion", "29") },
            "third FileProvider" to { r, _ ->
                val copy = share(r).cloneNode(true) as Element
                copy.setAttributeNS(android, "android:authorities", "${applicationId.get()}.other")
                share(r).parentNode.appendChild(copy)
            },
            ".share exported" to { r, _ -> share(r).setAttributeNS(android, "android:exported", "true") },
            "second path in share_paths.xml" to { _, s ->
                s.appendChild(s.ownerDocument.createElement("files-path").also { it.setAttribute("name", "x"); it.setAttribute("path", "") })
            },
            "INTERNET added" to { r, _ -> ask(r, "uses-permission", "android.permission.INTERNET") },
            "ACCESS_NETWORK_STATE as uses-permission-sdk-23" to { r, _ -> ask(r, "uses-permission-sdk-23", "android.permission.ACCESS_NETWORK_STATE") },
            "AD_ID added" to { r, _ -> ask(r, "uses-permission", "com.google.android.gms.permission.AD_ID") },
            "unknown permission added" to { r, _ -> ask(r, "uses-permission", "[PLACEHOLDER].permission.UNREVIEWED") },
        )
        for ((label, mutate) in mutations) {
            val r = parse(manifest.get().asFile)
            val s = parse(sharePaths.get().asFile)
            try {
                mutate(r, s)
            } catch (e: NoSuchElementException) {
                problems += "Self-test \"$label\" could not run: ${e.message}"
                continue
            }
            val found = problems(r, parse(cameraPaths.get().asFile), s)
            if (found.isEmpty()) problems += "Self-test failed: a merged manifest with \"$label\" was not refused."
            val name = namedIn[label]
            if (name != null && found.none { name in it && followFr12 in it }) {
                problems += "Self-test failed: \"$label\" was refused without naming $name and pointing to FEAT-016 FR-12."
            }
        }

        if (problems.isNotEmpty()) throw GradleException("checkMergedManifest failed:\n- " + problems.joinToString("\n- "))
        marker.get().asFile.apply { parentFile.mkdirs(); writeText("OK ${mutations.size} self-test mutations refused\n") }
        logger.lifecycle("checkMergedManifest: OK (${mutations.size} self-test mutations refused)")
    }
}

androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        val check = tasks.register<CheckMergedManifest>("checkMergedManifest") {
            manifest.set(variant.artifacts.get(SingleArtifact.MERGED_MANIFEST))
            cameraPaths.set(layout.projectDirectory.file("src/main/res/xml/camera_paths.xml"))
            sharePaths.set(layout.projectDirectory.file("src/main/res/xml/share_paths.xml"))
            applicationId.set(variant.applicationId)
            marker.set(layout.buildDirectory.file("outputs/privacy/checkMergedManifest.ok"))
        }
        tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }.configureEach { dependsOn(check) }
    }
}
