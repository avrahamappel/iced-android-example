with import <nixpkgs>
{
  overlays = [
    (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];

  config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };
};

let
  targets = [
    "aarch64-linux-android" # (64-bit ARM, used by most modern devices)
    "armv7-linux-androideabi" # (32-bit ARM, more supported)
    # "x86_64-linux-android" # (for Android emulators)
  ];

  rust-toolchain = rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ];
    inherit targets;
  };

  gradleBuildSettings = map (line: lib.splitString " = " (lib.trim line))
    (lib.splitString "\n" (builtins.readFile ./Android/app/build.gradle.kts));

  # Get a build setting by name
  # Ex: gradleBuildSetting "targetSdk"
  # => "37"
  gradleBuildSetting = name: lib.elemAt
    (lib.findFirst (words: (lib.elemAt words 0) == name)
      [ null null ]
      gradleBuildSettings) 1;

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    # abiVersions = [
    #   "armeabi-v7a"
    #   "arm64-v8a"
    # ];
    includeNDK = true;
    # minPlatformVersion = gradleBuildSetting "minSdk";
    # maxPlatformVersion = gradleBuildSetting "targetSdk";
  };

in

mkShell rec {
  packages = [
    jdk
    just
    rust-toolchain
    androidComposition.androidsdk
  ];

  TARGETS = targets;

  ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
  ANDROID_NDK_ROOT = "${ANDROID_HOME}/ndk-bundle";
  ANDROID_NDK_BIN = "${ANDROID_HOME}/ndk/${androidComposition.ndk-bundle.version}/toolchains/llvm/prebuilt/linux-x86_64/bin";
  JAVA_HOME = "${jdk.home}";
}
