set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
set dotenv-load
set unstable

min_sdk := "24"
targets := env("TARGETS")
name := "todolist"

variant := env("VARIANT", "debug")
profile := if variant == "debug" { "debug" } else if variant == "release" { "release" } else if variant == "nightly" { "release" } else { error("Invalid VARIANT: " + variant) }

alias b := build_gradle
alias build := build_gradle

[env("CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER", "aarch64-linux-android" + min_sdk + "-clang.cmd")]
[env("CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER", "x86_64-linux-android" + min_sdk + "-clang.cmd")]
[env("CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER", "armv7a-linux-androideabi" + min_sdk + "-clang.cmd")]
[env("PATH", env("ANDROID_NDK_BIN") + ";" + env("PATH"))]
[windows]
build_rust target:
    cargo build --target={{ target }} {{ if profile == "release" { "--release" } else { "" } }}

[env("CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER", "aarch64-linux-android" + min_sdk + "-clang")]
[env("CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER", "x86_64-linux-android" + min_sdk + "-clang")]
[env("CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER", "armv7a-linux-androideabi" + min_sdk + "-clang")]
[env("PATH", env("ANDROID_NDK_BIN") + ":" + env("PATH"))]
[unix]
build_rust target:
    cargo build --target={{ target }} {{ if profile == "release" { "--release" } else { "" } }}

abi(target) := if target == "aarch64-linux-android" { "arm64-v8a" } else if target == "armv7-linux-androideabi" { "armeabi-v7a" } else if target == "x86_64-linux-android" { "x86_64" } else { error("Unknown target: " + target) }
[unix]
copy_to_jni_folder target: (build_rust target)
    mkdir -p "Android/app/src/main/jniLibs/{{ abi(target) }}"
    cp target/{{ target }}/{{ profile }}/lib{{ name }}.so "Android/app/src/main/jniLibs/{{ abi(target) }}/"
[windows]
copy_to_jni_folder target: (build_rust target)
    New-Item -ItemType Directory -Force "Android/app/src/main/jniLibs/{{ abi(target) }}" | Out-Null
    Copy-Item target/{{ target }}/{{ profile }}/lib{{ name }}.so "Android/app/src/main/jniLibs/{{ abi(target) }}/"
[unix]
copy_to_jni_folder_:
    #!/usr/bin/env sh
    for target in {{ targets }}; do
        just copy_to_jni_folder $target
    done
[script("powershell")]
[windows]
copy_to_jni_folder_:
    foreach ($target in "{{ targets }}".Split(' ')) {
        just copy_to_jni_folder $target
    }
gradle_build_command(variant) := if variant == "debug" { "assembleDebug" } else if variant == "release" { "assembleRelease" } else if variant == "nightly" { "assembleNightly" } else { error("Unknown variant: " + variant) }

[default]
[working-directory('Android')]
build_gradle: copy_to_jni_folder_
    ./gradlew {{ gradle_build_command(variant) }}
apk-path := if profile == "debug" { "debug/app-debug.apk" } else { "release/app-release.apk" }
install:
    adb install -r Android/app/build/outputs/apk/{{ apk-path }}
launch:
    adb shell monkey \
        -p io.github.wiiznokes.todolist \
        -c android.intent.category.LAUNCHER \
        1
[env("ANDROID_NDK_ROOT", env("ANDROID_NDK_ROOT"))]
[env("JAVA_HOME", "/usr/lib/jvm/java-21-temurin-jdk")]
build_cargo_apk:
    RUST_LOG=debug cargo apk2 build --lib
