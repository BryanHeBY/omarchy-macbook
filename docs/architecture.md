# Repository architecture

[简体中文](architecture.zh-CN.md)

Omarchy MacBook groups desktop behavior by capability. A feature owns the files
needed to understand, configure and test that behavior.

## Feature ownership

Each directory under `features/` has an English `README.md` and Simplified Chinese
`README.zh-CN.md` explaining its purpose, files, dependencies, activation,
verification and recovery. Small features may contain a single configuration
file. Features with native code use `native/`;
shell plugins keep their complete runtime payload under `plugin/`.

Component helpers such as `configure.py`, `build.sh` and `configure.cjs` live with
their feature. Focused regression tests live under that feature's `tests/`.
Strict JSON manifests and translation catalogs are explained in their feature
README. Source comments use the file format's native comment syntax.

The complete QML payload, adjacent scripts and translation catalogs move together
so Qt relative URL resolution continues to work. Upstream copyright metadata is
retained, with license notices under `LICENSES/`.

## Installation policy and integration

`profiles/recommended.json` defines recommended feature selections and the input
profile. `install.py` validates it, applies explicit command-line overrides and
orchestrates dependencies, configuration and activation.

`installer/` owns shared deployment mechanisms. `symlinks.tsv` records a group,
a repository-relative source and a HOME-relative destination. `links.sh` installs
individual configuration files and complete plugin directories with backups.
`patches.sh` applies scoped integration patches with preflight and rollback.
Hyprland loader patches live under `installer/patches/`; feature-specific Fcitx5
patches live with the keyboard feature.

Workspace navigation and window-focus gestures have separate loaders. The
optional focus feature checks its opt-in marker before loading native code.
Compiling a library alone does not activate the feature.

## Runtime layout

Source paths are mapped to installed paths. Lua modules are linked individually
under `~/.config/hypr/customizations/`. Omarchy plugins are linked as complete
directories under `~/.config/omarchy/plugins/`. These installed aliases let user
configuration load modules independently of repository organization.

The keyd system configuration is a root-owned copy installed by the keyboard
helper. Runtime records, selection markers, caches, backups and native libraries
use user XDG configuration, state, cache and data directories. They stay outside
the tracked source tree.

The link installer can convert the previous repository-owned Hyprland directory
link into individual links. It backs up the parent link, copies remaining local
files and restores the parent link on failure. Concurrent additions are retained
in the failed-install backup directory.

## Documentation and tests

The root READMEs introduce the collection, list features and link to operational
guides. `docs/installation.md` covers activation and recovery. Feature READMEs
contain component details, and `docs/examples/` contains reference material.

Corresponding English and Chinese pages link to each other at the top. Chinese
pages prefer existing Chinese counterparts for documentation links. Code,
configuration, licenses and external references without translations retain
their original targets.

`tests/installation/` covers cross-feature orchestration, symlink migration,
patch application, backups and failure recovery. Component tests exercise their
own feature entry points. Run the commands in the root README from the repository
root.
