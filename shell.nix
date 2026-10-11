with import <nixpkgs>
{
  overlays = [
    (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];
};

let
  targets = [
    # "aarch64-linux-android" # (64-bit ARM, used by most modern devices)
    "armv7-linux-androideabi" # (32-bit ARM, more supported)
    # "x86_64-linux-android" # (for Android emulators)
  ];

  rust-toolchain = rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ];
    inherit targets;
  };
in

mkShell {
  packages = [
    just
    rust-toolchain
  ];

  TARGETS = targets;

  ANDROID_NDK_BIN = "."; # Just to calm down just
}
