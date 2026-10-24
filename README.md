# Rot and Light

A third-person game about a dark lord and the horde of minions he commands.
Built with Godot 4 and Rust. Public project slug: `rot-and-light`.

This is a **source-only** publication, not an open-source license or a
binary release. Original work is copyright © 2026 Simon W. Jackson,
**ALL RIGHTS RESERVED**. See [LICENSE](LICENSE),
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and the
[source audit](docs/source-audit.md) for scope and limits.

## Status

First playable slice: the dark lord, a horde of 20 minions, breakable
crates, and lamps, all placeholder shapes in a cel-shaded look. Send the
horde at a crate or a lamp, recall it. The [pitch](docs/pitch.md) describes
the direction, not a list of finished features.

- Every feel value is in `godot/tuning.tres`. Edit it while the game runs
  and press F5 (gamepad Back) to apply it.
- Every look value (tone bands, ink outlines, palette, glow, the burning and
  withering looks) is in `godot/look.tres`. F5 reloads it too.
- The look: three tone bands from `game/toon.gdshaderinc` on every solid
  thing, and ink outlines from one screen-space pass (`game/ink.gdshader`)
  that reads depth, plus normals in Forward+. Its cost depends on the
  screen size, not the horde size.
- Android build tooling is retained as source. See
  [docs/android.md](docs/android.md), including the new app identity.
- Debug demo for screenshots: `godot4 --path godot -- --demo` plays a short
  scripted run and prints `demo: <state>` lines and `demo perf:` frame
  times. `--demo-horde=40` starts with 40 minions, `--demo-uncapped` turns
  V-Sync off. Debug builds only.

## Local checks

From a clean Linux checkout, with Nix flakes enabled:

```sh
export EXPECTED_SOURCE_SHA=$(git rev-parse HEAD)  # record the full committed SHA
nix run .#check
```

The check task verifies that `HEAD` matches the recorded SHA before each
Cargo build or test. It rejects tracked edits. It checks Rust formatting
and Clippy, runs Cargo tests, builds the native binding, imports the Godot
project, and runs all six `godot/tests/*_test.gd` scripts, including touch.
Godot uses temporary config, data, and cache directories. The check does
not read the rig config, use a display, or change shared ADB state.

Godot is pinned to 4.7.2 and gdext to 0.5.5 (`api-4-7`). The native binding
must be built before importing a fresh checkout. Headless tests check
scripts and gameplay, **not** graphical output, GPU performance, or devices.

## Develop

```sh
nix develop          # or: direnv allow
export EXPECTED_SOURCE_SHA=$(git rev-parse HEAD)
test "$(git rev-parse HEAD)" = "$EXPECTED_SOURCE_SHA"
cargo build --locked
godot4 --headless --path godot --import
godot4 --path godot  # needs a display
```

Rendering verification requires the rig's real GPU; headless or Xvfb does
not verify visuals. `scripts/rig` is optional remote tooling, not part of
the local check. Its config names are now `ROT_AND_LIGHT_RIG` and
`ROT_AND_LIGHT_RIG_DIR`; update a private `.rig.env` explicitly before use.
No rig, signing key, installed app, or saved data is changed by publication.
