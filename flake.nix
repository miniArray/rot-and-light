{
  description = "Rot and Light: a game about a dark lord and his horde of minions";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # The Android SDK build tools in nixpkgs run on x86_64 Linux only.
      androidSystems = [ "x86_64-linux" ];
      forAndroid = f: nixpkgs.lib.genAttrs androidSystems (system: f (androidFor system));

      # The engine, its export templates, and the `api-4-*` feature of the
      # `godot` crate must all move together.
      godotVersion = "4.7.2";
      templatesUrl = "https://github.com/godotengine/godot-builds/releases/download/${godotVersion}-stable/Godot_v${godotVersion}-stable_export_templates.tpz";
      templatesHash = "sha512-yk1xxNe4HfwV0amLqgdTSqlbA/3aeKAHWwZnLhZI0uX0CYDJrcKNI+G5LnMu5780YZl6qASvdOwvzXqTzLhAeQ==";

      androidFor = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              android_sdk.accept_license = true;
              allowUnfree = true;
            };
          };
          godot =
            assert pkgs.godot_4.version == "${godotVersion}-stable";
            pkgs.godot_4;
          # Template exports need only build tools (apksigner, zipalign,
          # aapt2) and a platform. No NDK: the APK carries no Rust code.
          sdk = (pkgs.androidenv.composeAndroidPackages {
            buildToolsVersions = [ "36.0.0" ];
            platformVersions = [ "36" ];
            abiVersions = [ "arm64-v8a" ];
            includeEmulator = false;
            includeNDK = false;
            includeCmake = false;
          }).androidsdk;
          # The official templates, checked against a fixed hash. Only the
          # two Android APK templates are kept.
          templates = pkgs.runCommand "rot-and-light-android-templates-${godotVersion}"
            {
              nativeBuildInputs = [ pkgs.unzip ];
              archive = pkgs.fetchurl {
                url = templatesUrl;
                hash = templatesHash;
              };
            }
            ''
              mkdir -p "$out"
              for name in android_debug.apk android_release.apk version.txt; do
                unzip -p "$archive" "templates/$name" > "$out/$name"
              done
              test "$(cat "$out/version.txt")" = "${godotVersion}.stable"
            '';
          environment = {
            ROT_AND_LIGHT_GODOT = "${godot}/bin/godot4";
            ROT_AND_LIGHT_GODOT_VERSION = godotVersion;
            ROT_AND_LIGHT_ANDROID_TEMPLATES = "${templates}";
            JAVA_HOME = "${pkgs.jdk17}";
            ANDROID_HOME = "${sdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${sdk}/libexec/android-sdk";
          };
          packages = [ godot sdk pkgs.jdk17 pkgs.python3 ];
        in
        { inherit pkgs godot sdk templates environment packages; };
    in
    {
      devShells =
        nixpkgs.lib.recursiveUpdate
          (forAll (pkgs: {
            default = pkgs.mkShell {
              packages = with pkgs; [
                cargo
                rustc
                clippy
                rustfmt
                rust-analyzer
                # Keep in step with the `api-4-*` feature of `godot` in Cargo.toml.
                godot_4
              ];
              RUST_BACKTRACE = "1";
            };
          }))
          (forAndroid (android: {
            # `nix develop .#android`: the Android export toolchain.
            android = android.pkgs.mkShell (android.environment // {
              inherit (android) packages;
              shellHook = ''export PATH="$ANDROID_HOME/platform-tools:$PATH"'';
            });
          }));

      packages = forAndroid (android: {
        android-templates = android.templates;
        android-sdk = android.sdk;
      });

      # `nix run .#apk -- [--init-signing]` from the repository root builds
      # the signed APK on this machine. From another machine, use
      # `scripts/rig apk`.
      apps = nixpkgs.lib.recursiveUpdate
        (forAll (pkgs:
          let
            check = pkgs.writeShellApplication {
              name = "rot-and-light-check";
              runtimeInputs = with pkgs; [ bash coreutils git gnugrep python3 cargo rustc clippy rustfmt stdenv.cc godot_4 ];
              text = ''exec bash scripts/check "$@"'';
            };
          in {
            check = {
              type = "app";
              program = "${check}/bin/rot-and-light-check";
            };
          }))
        (forAndroid (android:
        let
          apk = android.pkgs.writeShellApplication {
            name = "rot-and-light-apk";
            runtimeInputs = android.packages;
            runtimeEnv = android.environment;
            text = ''exec python3 scripts/build-apk "$@"'';
          };
        in
        {
          apk = {
            type = "app";
            program = "${apk}/bin/rot-and-light-apk";
          };
        }));
    };
}
