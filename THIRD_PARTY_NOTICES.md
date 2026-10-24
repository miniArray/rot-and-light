# Third-party notices

Rot and Light is published as source only. The root `LICENSE` reserves
rights only in original work by Simon W. Jackson. It does not relicense the
engine, Rust bindings, generated dependency code, fonts supplied by the
engine, or development tools. No dependency source is vendored here and no
compiled engine, extension, APK, or export template is part of this source
publication.

## Engine and bindings

| Component | Pinned version | License and primary source |
|---|---|---|
| Godot Engine | 4.7.2-stable | MIT; [LICENSE.txt](https://github.com/godotengine/godot/blob/4.7.2-stable/LICENSE.txt), [COPYRIGHT.txt](https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt), [AUTHORS.md](https://github.com/godotengine/godot/blob/4.7.2-stable/AUTHORS.md) |
| gdext: `godot`, `godot-core`, `godot-ffi`, `godot-macros`, `godot-bindings`, `godot-codegen`, `godot-cell` | 0.5.5 each | MPL-2.0; [upstream](https://github.com/godot-rust/gdext/tree/v0.5.5), published crate `Cargo.toml` license fields and source headers |
| `gdextension-api` | 0.5.1 | MPL-2.0 crate declaration; its `src/gdextension_interface.json` also retains the Godot copyright/MIT notice; [upstream](https://github.com/godot-rust/gdext) |

Godot's MIT license does **not** make gdext MIT. MPL-covered dependency
files and generated dependency material keep their applicable notices and
source obligations. The separate original extension entry point is not a
copy of gdext. Future executable distribution must assess MPL-2.0
requirements, including access to the covered source and any modifications.
See the [MPL-2.0 text](https://www.mozilla.org/MPL/2.0/).

Godot also incorporates third-party software with other licenses. Its
`COPYRIGHT.txt` and the actual engine's `Engine.get_copyright_info()` and
`Engine.get_license_info()` are the starting points, not the engine's MIT
headline alone. The engine's bundled font and libraries are not original
Rot and Light media. The project icon is a separate primitive placeholder,
not the Godot logo. Godot's logo has its own CC-BY-4.0 notice in the engine
inventory; this does not license this project's icon or original work.

| Runtime material supplied by Godot | License / credit | Source-publication boundary |
|---|---|---|
| Default font, Open Sans SemiBold | OFL-1.1; copyright 2020 The Open Sans Project Authors | `touch_controls.gd` uses `get_theme_default_font()`; no font file is in this repository. See Godot's `COPYRIGHT.txt` Open Sans entry, `scene/theme/SCsub`, and the [upstream font notices](https://github.com/godotengine/godot/tree/4.7.2-stable/thirdparty/fonts). |
| Default boot splash, Godot logo | CC-BY-4.0; Andrea Calabró | The project does not override the engine splash. It is not original game art. See Godot's logo copyright entry and [official press kit](https://godotengine.org/press/). |

For a future binary release, preserve the font's OFL text and applicable
notices, and the logo's attribution/license requirements if the logo remains
in the artifact. Their presence does not turn original additions into OFL,
CC-BY, MIT, or CC0 work.

### Godot MIT notice

The installed 4.7.2 engine returns this notice from
`Engine.get_license_text()` (checked 2026-10-24):

> Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
> Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

## Other locked Rust dependencies

These are all the other registry packages in `Cargo.lock`, including
build-time and procedural-macro dependencies. License expressions were
checked in the corresponding published crate manifests on 2026-10-24.
They are inventory entries, not grants of rights in original game code.

| Crate | Version | Declared license | Primary repository |
|---|---|---|---|
| glam | 0.32.1 | MIT OR Apache-2.0 | [glam-rs](https://github.com/bitshifter/glam-rs) |
| heck | 0.5.0 | MIT OR Apache-2.0 | [heck](https://github.com/withoutboats/heck) |
| libc | 0.2.190 | MIT OR Apache-2.0 | [libc](https://github.com/rust-lang/libc) |
| nanoserde | 0.2.1 | MIT OR Apache-2.0 | [nanoserde](https://github.com/not-fl3/nanoserde) |
| nanoserde-derive | 0.2.1 | MIT | [nanoserde](https://github.com/not-fl3/nanoserde) |
| proc-macro2 | 1.0.107 | MIT OR Apache-2.0 | [proc-macro2](https://github.com/dtolnay/proc-macro2) |
| quote | 1.0.47 | MIT OR Apache-2.0 | [quote](https://github.com/dtolnay/quote) |
| unicode-ident | 1.0.27 | (MIT OR Apache-2.0) AND Unicode-3.0 | [unicode-ident](https://github.com/dtolnay/unicode-ident) |
| venial | 0.6.1 | MIT | [venial](https://github.com/PoignardAzur/venial) |

`unicode-ident` includes `LICENSE-UNICODE`, copyright © 1991-2023 Unicode,
Inc.; that notice applies in addition to the MIT/Apache choice. `venial`'s
MIT notice credits copyright (c) 2022 Olivier FAURE. Keep upstream license
and copyright files with any future redistribution of their source or
compiled material. The local published gdext crates and `nanoserde-derive`
do not carry standalone `LICENSE` files; their manifest/source declarations
were checked, not assumed from a missing file.

## Development and Android tooling

`flake.lock` pins nixpkgs to
`7fd4004d0511991fff3a0524856a9be09e28c5f0`. Nix, Rust/Cargo/Clippy/rustfmt,
Bash, Python, Git, and the local shell tools keep their upstream licenses.
Android tooling additionally selects Godot's official 4.7.2 templates,
Android SDK build tools 36.0.0, platform 36, and JDK 17. Those are tools and
external inputs, not original source released under the root notice.
The Android shell explicitly accepts the SDK license and allows unfree
packages. Do not interpret that configuration as permission to redistribute
the SDK or templates without review.

This inventory is **not** a transitive binary-compliance guarantee. No APK,
native library, Godot export, SDK, JDK, or Linux runtime closure has been
prepared for distribution here. Before a binary release, audit the actual
built artifact, bundled third-party notices and fonts, native dependencies,
MPL-covered source availability, template contents, and platform terms.
Upstream URLs above identify primary sources; this preparation used cached
published crates and the installed engine, not remote fetches. See
[the source audit](docs/source-audit.md) for evidence and limits.
