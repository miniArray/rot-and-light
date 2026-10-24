# Android build

Rot and Light retains signed arm64 APK tooling for phone playtests. This
publication ships source only. No APK is built, signed, installed, or verified
on a device as part of publication. Nothing builds on the phone.

## App identity change

The new package is `dev.rotandlight.prototype`, labelled **Rot and Light**.
It is a separate app from the old `dev.gnarl.prototype`, not an in-place
update. The old app and its files stay where they are. New installs use the
new package's external files directory shown below. There is no automatic
data migration. Do not uninstall the old app or move its files as part of
publication. Desktop `user://` also follows the new project name; no existing
user directory is moved or deleted.

Signing still uses the established `~/.local/share/gnarl/android-signing/`
and key alias `gnarl`. These are intentional storage/identity exceptions,
not old-name command aliases. Do not rename or recreate an existing key.

## Build

For a later, separately approved binary build, first record and check the
full committed source SHA in the build checkout:

```sh
export EXPECTED_SOURCE_SHA=$(git rev-parse HEAD)
test "$(git rev-parse HEAD)" = "$EXPECTED_SOURCE_SHA"
```

The following remote commands are retained tooling, not publication steps.
Update private rig config to `ROT_AND_LIGHT_RIG` and
`ROT_AND_LIGHT_RIG_DIR` explicitly before use:

```sh
scripts/rig apk                  # sync to the rig, export, copy the APK back
scripts/rig apk --init-signing   # the first build on a new rig only
```

The APK lands in `build/android/` here (git ignores it):

| File | Content |
|---|---|
| `rot-and-light.apk` | The signed APK |
| `rot-and-light.apk.sha256` | Its SHA-256 (`sha256sum -c rot-and-light.apk.sha256`) |
| `manifest.json` | Engine, template hashes, source revision, signer, checks |

On a machine with the toolchain and a checkout, `nix run .#apk` builds in
place. `nix develop .#android` gives the same toolchain as a shell.

`scripts/build-apk` does the work. It:

1. Checks that Godot and the export templates are the same version (4.7.2).
2. Stages a copy of `godot/` without `tests/`, `debug/`, and the Rust
   extension.
3. Imports and exports it with Godot settings in a temporary folder. The
   rig's own Godot settings stay untouched.
4. Verifies the APK and publishes it only if every check passes:
   - `apksigner verify` succeeds.
   - Only `lib/arm64-v8a/` holds native libraries.
   - The package is `dev.rotandlight.prototype` 0.2.0, version code 2.
   - It asks for no permissions.
   - No Rust extension file is in it.

Any Godot `ERROR:` line also fails the build.

## Toolchain

`flake.nix` pins all of it through `flake.lock`:

- Godot `godot_4`. The flake asserts version 4.7.2.
- The official 4.7.2 export templates, fetched with a fixed SHA-512. Only
  the two Android APK templates are kept.
- Android SDK build tools 36.0.0 and platform 36, with no NDK, CMake, or
  emulator.
- JDK 17.

If you move Godot to a new version, change `godotVersion` and
`templatesHash` in `flake.nix` together. Get the hash with:

```sh
nix store prefetch-file --hash-type sha512 <templates url>
```

## Signing

The build script uses `~/.local/share/gnarl/android-signing/`
(`release.keystore` and `password`, mode 600) on the build machine, with key
alias `gnarl`. Existing private files were not inspected for publication.
Never commit them. Back up both files privately. A phone accepts an update
to the same package only when the APK has the same key. The new package
identity does not update the old app, even if signed with that key.

`--init-signing` can create a key only if one does not exist. Do not run it
as part of source publication. A future binary release also needs a separate
review of the engine, templates, native dependencies, and SDK license terms;
see [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## The Rust extension is not in the APK

`godot/rot-and-light.gdextension` lists desktop libraries only. The build removes it
from the staged project, so the APK has no GDExtension and the game starts
with no extension error.

- **Why:** the extension holds no gameplay yet. Cross-compiling it needs the
  NDK in the flake and an `aarch64-linux-android` Rust target.
- **Cost:** Rust code does not run on Android. Before gameplay moves into
  Rust, add the NDK and an Android library entry to `rot-and-light.gdextension`, and
  remove it from `UNSTAGED` in `scripts/build-apk`.

## Install

The package is `dev.rotandlight.prototype`, version 0.2.0 (code 2). It has no
permissions, it is immersive, and it turns between the two landscape
orientations with the device (sensor landscape). It uses the Mobile renderer.

Over ADB:

```sh
adb devices -l
adb -s SERIAL install -r build/android/rot-and-light.apk
adb -s SERIAL shell am start -n dev.rotandlight.prototype/com.godot.game.GodotAppLauncher
```

Without ADB, send the file to the phone and open it there. You may need to
allow installs from that source. Samsung Auto Blocker can block the install.

## Tuning and look on the phone

An APK cannot read `godot/tuning.tres` or `godot/look.tres`. At start and
on RELOAD, the game uses these files when they exist:

```
/sdcard/Android/data/dev.rotandlight.prototype/files/tuning.tres
/sdcard/Android/data/dev.rotandlight.prototype/files/look.tres
```

Push an edited copy, then tap RELOAD:

```sh
adb -s SERIAL shell mkdir -p /sdcard/Android/data/dev.rotandlight.prototype/files
adb -s SERIAL push godot/tuning.tres /sdcard/Android/data/dev.rotandlight.prototype/files/
adb -s SERIAL push godot/look.tres /sdcard/Android/data/dev.rotandlight.prototype/files/
```

The Mobile renderer has no normal buffer, so on the phone the ink outlines
come from depth only: silhouettes and steps, but no lines at creases such
as the edges of a crate face. `ink_crease_degrees` does nothing there.

## Touch controls

Touch controls show only on a touchscreen. On desktop, run with `-- --touch`
to show them.

| Control | Where | Does |
|---|---|---|
| Stick | Left half, starts under the thumb | Presses `move_*` with analog strength |
| Look | Drag on the right half | Turns the camera (`touch_look_sensitivity`) |
| SEND | Bottom right, 92 dp | The `send` action |
| RECALL | Left of SEND, 72 dp | The `recall` action |
| RELOAD | Top right, 48 dp | The `reload_tuning` action |

- Sizes are in dp, from the screen DPI.
- The layout stays inside the display safe area. It redoes itself when the
  window changes size (fold, unfold, rotate) and releases every held touch
  then.
- Mouse emulation from touch is off, so a tap never acts as a mouse click.

`tests/touch_test.gd` checks the touch controls with injected screen
touches:

- The layout fits the folded and unfolded screen sizes.
- The stick walks the lord.
- Send works with a second finger while the stick is held.
- Recall and Reload work.
- A drag turns the camera.

## Not verified

- No phone has run this APK.
- Real multitouch, the safe area on the device, fold transitions, frame rate,
  heat, and battery use need a device test.
