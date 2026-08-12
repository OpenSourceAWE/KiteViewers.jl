# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## What this package is

KiteViewers.jl is the 3D visualization package of the "Julia Kite Power Tools" family (siblings:
`KiteUtils`, `KiteModels`, `WinchModels`, `KitePodModels`, `AtmosphericModels`, `KiteControllers`,
bundled by the meta-package `KiteSimulators`). It renders a kite power system — tether particles,
tether/bridle segments as cylinders, a kite mesh, a status text overlay and a row of control
buttons — in a GLMakie window, and updates it from a `KiteUtils.SysState`.

It contains **no simulation code**. The data flow is always: some caller (a `KiteModels` simulation,
a log replay, or an external system over HTTP — see `examples/show_messages.jl`) produces a
`SysState` and calls `update_system(viewer, state)`. `KiteModels` is a test/example dependency only,
never a runtime one.

## Architecture

### One module, three files

`src/KiteViewers.jl` is the module: exports, the `KITE_SPRINGS`/`POS_X`/`POS_Y` constants,
`default_viewer_font`, the `install_examples`/`copy_examples`/`copy_viewer_settings` helpers, the
macOS-only window-focus helpers (`bring_viewer_to_front`, `reactivate_host_app`, no-ops elsewhere),
`__init__`, and the `PrecompileTools` workload. It includes `src/viewer3D.jl` (the `Viewer3D` type,
its two constructors, the module-level observables, `clear_viewer`/`stop`/`pause`/`set_status`,
`save_png`) and `src/common.jl` (`create_coordinate_system`, `init_system`, `update_system`,
camera helpers `reset_view`/`zoom_scene`/`reset_and_zoom`).

`KiteUtils` is `@reexport`ed, as is `GLMakie: on` — callers get `SysState`, `se()`,
`load_settings`, `demo_state*` and the `on(...)` needed to hook up buttons without importing
anything else.

### The pieces that need reading several files to see

- **Viewer state is module-global, not per-instance.** `quat`, `kite_pos`, `textnode`, `textnode2`,
  `status`, `plot_file`, `running`, `zoom`, `FLYING`/`PLAYING`/`GUI_ACTIVE` and `last_status` are
  `@consts`/globals in `src/viewer3D.jl`, shared by every `Viewer3D`. Only the tether observables
  (`points`, `positions`, `part_positions`, `markersizes`, `rotation`) live in the struct. Two
  simultaneous viewers therefore fight over the kite orientation and all text — treat the package as
  single-viewer.
- **Some constants are frozen at precompile time.** `KITE` (the mesh, `FileIO.load` of `se().model`),
  `INITIAL_HEIGHT`, `MAX_HEIGHT` and `TEXT_SIZE` are evaluated when the module is compiled, using
  whatever `se()` returns then — not the `set` later passed to `Viewer3D`. Changing `model` or `zoom`
  in a settings file does not take effect until the package is recompiled.
- **`update_system` picks the kite model from `length(state.Z)`,** not from a setting: `segments+1`
  = one-point model, `segments+5` = four-point model (adds the 8 `KITE_SPRINGS` bridle cylinders and
  scales the four kite points away from the pod by `kite_scale`), `segments*3+6` = the three-line
  four-point model (points come in left/middle/right triples and are spread apart along the kite's
  y axis). Everything downstream — `calc_positions`/`calc_markersizes`/`calc_rotations`, which
  place, size and rotate one cylinder per segment — branches on the same three cases, so a new kite
  topology means touching all of them.
- **Two scale factors, and the NED question.** `scale` shrinks the whole system into the scene
  (simulations use `scale=0.08` with `kite_scale=3`); `kite_scale` enlarges the kite relative to its
  pod/attachment point. `ned=true` (the default) converts `state.orient` from NED with
  `quat2viewer`; the `demo_state*` examples pass `ned=false` because those states are already in
  viewer convention. Makie's `Quaternionf` wants `x,y,z,w` while `SysState.orient` is `w,x,y,z` —
  the swap happens in `update_system`.
- **Buttons are plain Makie observables on the struct** (`btn_PLAY`, `btn_STOP`, `btn_RESET`,
  `btn_ZOOM_in/out`, `btn_AUTO`, `btn_PARKING`, the `sw` repeat toggle). The viewer wires up only
  zoom/reset/stop/play itself; the application adds behaviour with
  `on(viewer.btn_PLAY.clicks) do c ... end` — see `examples/depower_simple.jl` and
  `examples/joystick.jl`. The `menus=true` constructor keyword adds the plot/rel_tol/time_lapse/
  project dropdowns and the `t_sim` textbox, which are `nothing` otherwise
  (`examples/menus_4p.jl`).
- **Text layout is pixel-positioned** relative to a 840x900 window: the lower-left block is fixed,
  the upper-right block is re-anchored on every viewport/window-area change by
  `update_upper_right_text` (the closure returned over `txt2` from `init_system`). Nudging text means
  touching `POS_X`/`POS_Y` and that closure together.
- **`__init__` sets the data path to `./data`** if the current directory has a `data/system.yaml`.
  Examples and tests therefore assume the REPL is at the repo root; `se()` fails or reads the wrong
  settings otherwise.

### Configuration

Settings come from `KiteUtils` (`data/system.yaml` selects `data/settings.yaml`; `3l_settings.yaml`
is the three-line variant). The keys this package reads are `segments`, `zoom`, `kite_scale`,
`fixed_font` (empty = platform default from `default_viewer_font`) and `model` (path to the kite
`.obj`). `data/` also holds replay fixtures: `tmp_parking.arrow` and `v3_segments.csv`.

## Development commands

Workspace-based: `Project.toml` declares `[workspace] projects = ["examples", "docs", "test"]`, but
**there is no `test/Project.toml`** — tests run through the classic `[extras]`/`[targets]` test
target, and the test scripts activate it themselves with `TestEnv.activate()` when `KiteModels` is
missing. `TestEnv` must be installed in the global environment.

- **Install/setup**: `cd bin && ./install` (juliaup; asks for Julia 1.11 or 1.12, copies the matching
  `Manifest-v1.xx.toml.default`, then resolves/instantiates the main, examples and docs projects).
  The `Manifest-v1.11.toml`/`Manifest-v1.12.toml` files are gitignored; only the `.default` ones are
  tracked. Regenerate a default with `examples/update_manifest.jl` and commit it.
- **Launch a dev REPL**: `./bin/run_julia` (aliased to `jl` by the installer). It sets `NO_MTK=true`,
  picks GC/compute threads, and starts with `using KiteViewers`; it also picks up a
  `bin/kps-image-<version>-<branch>.so` system image if one was built.
- **Run the tests**: `julia --project -e 'using TestEnv; TestEnv.activate(); include("test/runtests.jl")'`
  (what CI does, under `xvfb-run` with `DISPLAY=:0`). Do **not** `include("test/runtests.jl")` in a
  shared REPL: the script calls `cd("..")` at top level (it assumes `Pkg.test`'s working directory
  `test/`) and will move the REPL out of the repo. `test/runtests.jl` includes `test_parking.jl` —
  a real 20 s `KPS4` simulation driving the viewer — and then asserts elevation, azimuth and winch
  force on its final state; `test_steering.jl` is a second, longer scenario that the runner does not
  include. `test/test_dev` and `test/test_main_branch` are shell scripts that install the package
  from git / from the registry into a throwaway depot.
- **Run examples**: `include("examples/menu.jl")` from the repo root. `basic_1p.jl`/`basic_4p.jl` are
  the demo-state ones needing no simulation; the rest drive `KiteModels`. `*_bench_video.jl` writes
  PNG frames via `save_png` into `video/` (gitignored) for ffmpeg.
- **Build docs**: `include("scripts/build_docu.jl")` serves them live with `LiveServer`
  (needs `LiveServer` in the global environment); `docs/make.jl` is the plain Documenter build.
- **Opening a display is required**: everything here needs a working OpenGL context. Headless runs
  need `xvfb-run`; the precompile workload skips creating a viewer unless `DISPLAY` is set.

## Coding style

Same conventions as the sibling packages (see `KiteModels.jl`'s `CLAUDE.md`): 120-char line limit,
named constants over magic numbers, space around binary operators, `Revise` installed globally and
never as a project dependency. Markdown is linted with the `.markdownlint.json` in the repo root;
JETLS settings live in `.JETLSConfig.toml`. Keep `CHANGELOG.md` current — new entries go under
`## Unreleased` until the version in `Project.toml` is bumped.
- Inline comments are ONLY allowed when stating a very non-obvious fact, and
  then keep them to 1 line at most. Give every type/function a docstring ("""
  not #) instead, but not too verbose, people won't reed it if your docstring is
  too long, and explain how the code works in the docstring, but not the whole
  story behind it.
- Remove or make inline comments 1 line where you see them.
- In YAML files, consider the comments at the top of the file as docstring where you can add multiline comments.
- Everything with a docstring should be added to the docs, otherwise you get an
  error when building the docs.

