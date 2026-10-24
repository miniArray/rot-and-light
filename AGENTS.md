# Rot and Light

Rot and Light is an original third-person game: a dark lord commands a horde of
minions. It is a spiritual successor to games of that kind, and it is meant
to ship commercially. Public project slug: `rot-and-light`.

This is a source-only publication. Original work remains copyright
© 2026 Simon W. Jackson, ALL RIGHTS RESERVED; see `LICENSE` and
`THIRD_PARTY_NOTICES.md`. Do not relicense original additions as MIT or CC0.

## Originality rules

These rules protect the game's right to be sold.

1. **Everything is our own.** Code, art, sound, text, levels, names, and
   numbers. Use no files, assets, scripts, or data from any other game.
2. **No reverse-engineering material.** An earlier project, `gnarl-re`
   (`~/code/sandbox/gnarl-re`, private and archived), studied another game's
   files. Never open it, its `research/` or `specs/`, or anything derived
   from it while working here. Do not copy its code.
3. **Ideas are free; expression is not.** Genre mechanics (a horde that
   follows, sweeping, recalling, minion types) are fine. Do not copy another
   game's names, characters, story, text, level layouts, art style, or tuning
   values.
4. Do not use "Overlord" in any name, text, or asset.

## Layout

- `godot/`: the Godot project. Scenes and resources are text; edit them
  directly. Early gameplay is GDScript, because feel needs fast iteration.
- `crates/rot-and-light-godot`: the gdext extension. Gameplay logic moves to plain
  Rust crates once it settles or needs tests.

## Toolchain

`nix develop` (or direnv) gives cargo and Godot (`godot4`).

- Godot comes from the nixpkgs pinned in `flake.lock` (4.7.2 today). The
  `godot` crate is pinned to `=0.5.5` with feature `api-4-7`. Change both
  together, or the extension will not load.
- gdext is pre-1.0. Read its changelog before any bump.

## Local checks and publication

`EXPECTED_SOURCE_SHA=<full committed SHA> nix run .#check` runs the local
complete headless check. It builds the native binding before importing the
project. Godot uses private temporary XDG config/data/cache, with
`export/android/shutdown_adb_on_exit=false`; do not stop shared ADB.
Headless checks do not verify rendering. Before each source build, check
`test "$(git rev-parse HEAD)" = "$EXPECTED_SOURCE_SHA"` in that checkout.

Do not include build output, caches, screenshots, rig config, or signing
files in a source snapshot. The Android app now has a new identity; see
`docs/android.md`. Keep existing installed data and signing files untouched.

## The rig

The GPU is on another machine, the rig. Edit here; build, test, and play on
the rig with `scripts/rig`. It reads the ssh host and the rig's checkout
path from `.rig.env` in the main checkout (git ignores it).

```sh
scripts/rig test   # rsync this tree, then cargo test
scripts/rig play   # build, import, open Godot on the rig's display
scripts/rig logs   # Godot's output; scripts/rig stop closes the window
scripts/rig shot   # screenshot of the rig's display into shots/
```

- `sync` makes the rig's tree a copy of yours, uncommitted edits included.
  It never touches the rig's `target/` or `godot/.godot/`.
- A linked worktree syncs to `<rig dir>/.worktree/<name>`.
- `--headless` works for scripts, tests, and imports. Anything that must
  render needs the rig's real GPU; Xvfb hides real visuals.
