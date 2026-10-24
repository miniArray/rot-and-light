# Source publication audit — 2026-10-24

## Scope

Preparation source: commit
`6cd854f5d25623cd2cfc83e091b87eb6a8035483` of the existing game repository,
plus the publication changes on `publish/rot-and-light`.
Public name: **Rot and Light**. Slug: `rot-and-light`.

This is a scoped source review, not a legal opinion, an exhaustive
originality proof, or approval to distribute binaries. A fresh source
snapshot must receive its own final pinned full test and secret scan before
publication. This document does not claim those final checks have run.

## Evidence reviewed

| Area | Evidence | Finding and limit |
|---|---|---|
| Authorship | Existing Git log for the tracked game, including `godot/icon.svg` at `99580ea8b5ff1f1daf3d08ad08e0071d6df6a788` | Recorded author is Simon W. Jackson. Git attribution alone does not prove ownership of every expression or formula. |
| Project media | Tracked-file inventory; `godot/icon.svg`; `godot/main.tscn` and `godot/game/*.tscn`; game and shader sources | The only tracked image is a short SVG made of rounded rectangles. Scene meshes are Godot primitives. Sparks use a generated gradient in `minion.gd`; rot and toon appearance use shaders. No external image, model, audio, video, or font file was observed in the tracked source. This is not a claim about untracked or historical media. |
| Resources and text | `godot/tuning.tres`, `godot/look.tres`, GDScript, shaders, debug/tests, `docs/pitch.md` | Current game data and expression were reviewed as source. No external game asset reference was observed. Similar generic mechanics or shader arithmetic do not establish provenance. No comparison to excluded material was made. |
| Originality rule | `AGENTS.md` | The existing prohibited-project pointer and its prohibition are retained. The excluded project and its material were not opened, searched, or used. No dependency on it was introduced. |
| Native dependencies | Root/crate Cargo manifests, `Cargo.lock`, local published registry manifests and source headers | Godot Rust binding crates declare MPL-2.0, not MIT. The lock contains 17 registry packages; all are inventoried in `THIRD_PARTY_NOTICES.md`. No crate source is vendored in the source publication. |
| Engine license | Installed Godot `4.7.2.stable.nixpkgs.ed1daf0bf`, `Engine.get_license_text()` and `Engine.get_copyright_info()`; Godot copyright header in `gdextension-api` | The engine reports the Godot MIT notice and a separate third-party inventory. This does not audit the runtime closure or Android template contents. Primary upstream license links are supplied, not claimed as remotely fetched. |
| Engine-supplied runtime media | `touch_controls.gd` default font call, no splash override in `project.godot`, engine copyright inventory; independent baseline audit of Godot `COPYRIGHT.txt` and `scene/theme/SCsub` | Runtime default font is Open Sans SemiBold (OFL-1.1), and default splash is the Godot logo (CC-BY-4.0). Neither is claimed as original game art. No font or logo file is vendored in the source. |
| Transitive Rust exceptions | Published `unicode-ident` manifest/`LICENSE-UNICODE`, `venial` `LICENSE`, other locked crate manifests | Unicode-3.0 applies in addition to the MIT/Apache choice for `unicode-ident`; `nanoserde-derive` and `venial` declare MIT. Standalone license files are absent in the cached gdext crates and `nanoserde-derive`; declarations and headers, where present, are the evidence. |
| Build/export tooling | `flake.nix`, `flake.lock`, `scripts/build-apk`, `scripts/rig`, `scripts/rig-side`, export preset | Reviewed as source only. Rig commands, `.rig.env`, private keys, and device operations were not used. SDK acceptance and unfree tooling are retained configuration, not a binary redistribution clearance. |

## Publication changes

- Original work has a scoped **ALL RIGHTS RESERVED** notice credited to
  Simon W. Jackson. Dependencies keep their own terms. Public source access
  is not an MIT/CC0 grant for original additions.
- The native crate is `rot-and-light-godot`; the Rust library filename is
  `rot_and_light_godot`. `godot/rot-and-light.gdextension` points at
  `../target/{debug,release}`. No old-name command/environment aliases were
  added. `scripts/check` fixes Cargo's target directory to that location.
- The visible title is Rot and Light. The Android identity is now
  `dev.rotandlight.prototype`, a separate app. Its tuning/look path matches
  that identity. Existing installations and files stay untouched.
- The established private signing directory and key alias deliberately keep
  their storage names. No key or password was read, created, moved, or
  deleted. No automatic installed-data migration was added.
- Gameplay, tuning values, scene layout, shaders, and the placeholder icon
  are unchanged, apart from the Android package-specific file path. The
  pitch title no longer says “working title”.
- `nix run .#check` provides the local complete check. The runner now fails
  on a failed second import and does not retry away script errors. Godot
  config/data/cache are temporary, and the editor cannot stop shared ADB on
  exit. Runner regression cases use controlled local subprocesses, not a
  substitute gameplay implementation.

## Verification boundary

Preparation runs focused runner regressions and source/static checks. The
parent publication review must run the complete check once on the final
clean snapshot, with its own recorded full source SHA:

```sh
export EXPECTED_SOURCE_SHA=$(git rev-parse HEAD)
test "$(git rev-parse HEAD)" = "$EXPECTED_SOURCE_SHA"
nix run .#check
```

That task builds the binding before Godot import and all six game tests.
Godot 4.7.2 can abort on a first import; an exit-only failure can retry once,
but any script/engine error or a second failed exit fails the task. This is
not a graphics test. No graphical, rig GPU, Android/device, APK signing, or
binary redistribution verification is claimed.

## Remaining limits and release gate

1. Publish tracked source only, without history from unrelated projects,
   ignored build/cache output, rig configuration, screenshots, APKs, signing
   data, or local profiles. The prohibition pointer itself must remain.
2. The final publisher must record the exact clean snapshot SHA, run the
   complete check and secret scan against it, and inspect the export itself.
   This preparation does not create a remote repository or upload anything.
3. A human must confirm rights in the original expression. Source review and
   author metadata cannot prove originality or clear trademarks for a title.
4. A future executable release needs artifact-specific third-party notices,
   engine/native/font/template review, and MPL source-availability review.
   This source-only inventory does not clear that release.
