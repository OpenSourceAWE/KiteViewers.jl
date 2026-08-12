# Plan: show the V3 kite in KiteViewers

## Goal

KiteViewers currently renders three hard-coded topologies (one-point, four-point, four-point 3L),
selected in `update_system` by `length(state.Z)`. Add a fourth, *data-driven* path that renders an
arbitrary point/segment structure, and use it to replay a V3 kite log produced by
`V3Kite`/`SymbolicAWEModels`.

The V3 support must not pull `SymbolicAWEModels` into KiteViewers: replay needs only the `.arrow`
log (via `KiteUtils`) plus a segment table. This keeps the "no simulation code" rule of
`CLAUDE.md` intact.

## Facts established about the input data

Verified by reading `data/tmp_parking.arrow` and `data/v3_segments.csv` (2026-08-12).

- **The log**: 601 rows, `t = 0 … 10 s`, `dt = 1/60 s` (written by `V3Kite`
  `examples/simple_parking.jl`, `DT = 0.05/3`, copied here from its `output/` folder).
- **`length(state.Z) == 334`**, laid out by `SymbolicAWEModels.position_slots`:
  | slots | content |
  | --- | --- |
  | 1:44 | structural points — exactly the indices used by `v3_segments.csv` |
  | 45:332 | VSM panel corners (72 panels × 4, `n_panels: 72` in V3Kite `data/vsm_settings.yaml`) |
  | 333 | wing origin |
  | 334 | rigid-body (KCU) origin |
  Only slots 1:44 are needed. Slots 333/334 coincide with point 1 in frame 1 of this log — do not
  rely on that, just ignore them.
- **The segment table**: 95 segments, all 44 point indices used, no gaps. Types: 46 `wing`,
  43 `bridle`, 6 `tether`. Point 39 is the ground anchor (0,0,0); point 1 is the bridle/KCU point;
  the tether runs `1→40→41→42→43→44→39`.
- **Orientation format**: the log stores `Qw/Qx/Qy/Qz` (one entry per oriented frame, here 2), not
  the legacy single `orient` column.

## Blockers found (fix before writing the example)

1. **The pinned `KiteUtils` cannot read this log.** With the manifest as committed
   (`KiteUtils 0.11.4`), `load_log("data/tmp_parking.arrow")` throws
   `KeyError: key :orient not found` — the `Qw/Qx/Qy/Qz` fallback landed in `KiteUtils 0.11.13`
   (registered). The `compat = "0.11.2"` entries already allow it, so a `Pkg.update` suffices, but
   bump `compat` to `"0.11.13"` in `Project.toml` **and** `examples/Project.toml` to make the
   requirement explicit, then regenerate and commit `Manifest-v1.11.toml.default` and
   `Manifest-v1.12.toml.default` with `examples/update_manifest.jl`.
2. **`update_system` cannot be reused as-is.** For `length(state.Z) == 334` all three topology
   flags are `false`, so no point is written, and the next line
   (`kv.part_positions[] = [kv.points[k] for k in 1:length(state.Z)]`) raises a `BoundsError`:
   `kv.points` is allocated in the `Viewer3D` constructor with `set.segments*3+6 == 24` entries.
   The observables `positions`/`markersizes`/`rotation` are likewise fixed at
   `set.segments+KITE_SPRINGS == 14`.

## Design

### Where the code goes

Put the reusable part in `src/`, keep the example thin — KiteViewers is the visualization package,
and a 95-segment renderer written inside `examples/park_v3.jl` would not be reusable by
`KiteSimulators` or by a live `SymbolicAWEModels` run later.

New code in `src/common.jl` (all with docstrings, all added to `docs/src/reference.md`, otherwise
the docs build fails):

- `@enum SegmentType TETHER=1 BRIDLE=2 WING=3` — the numeric encoding of the third column below.
  Callers pass plain `Int`s; the enum only names them and keeps the appearance table honest.
- `init(kv, segments::Matrix{Int}; radii, colors)` — the topology entry point. `segments` is
  `n × 3`: `point1`, `point2`, `segment_type`. It resizes `kv.points` and the four observables to
  the point/segment counts implied by the matrix (`n_points = maximum(segments[:, 1:2])`) and adds
  the meshscatter layers. **This is the only interface a caller needs**, so an application built on
  `SymbolicAWEModels` can flatten its `SystemStructure` into a plain integer matrix and hand it
  over — KiteViewers never sees that package. *Naming note*: `init` is a very generic exported
  name; V3Kite exports `init` and `SymbolicAWEModels` exports `init!`, so a script that does
  `using KiteViewers, V3Kite` gets an ambiguity that forces `KiteViewers.init(...)` at the call
  site. `init_segments!` would avoid that. Going with `init` as requested.
- `load_segments(filename) -> Matrix{Int}` — convenience loader that produces exactly that matrix
  from a CSV like `data/v3_segments.csv`, mapping the `tether`/`bridle`/`wing` strings onto the
  enum values. Parsed with `readlines` + `split`: deliberately no `CSV.jl`/`DelimitedFiles`
  dependency for a 96-line file. The CSV's first column is dropped — verified to be nothing but
  the row number (1…95, in order).
- `update_segments!(kv, state; scale)` — write slots `1:n_points` of the state into `kv.points`,
  then recompute midpoints, lengths and unit vectors per segment from the segment matrix instead of
  from the `k → k+1` assumption baked into `calc_positions`/`calc_markersizes`/`calc_rotations`.

### Per-type appearance in one draw call

`markersize` on a `meshscatter` scales the marker on all three axes, and the existing marker is
`Cylinder(Point3f(0,0,-0.5), Point3f(0,0,0.5), 0.035*SCALE)`. So a per-instance
`Point3f(r_rel, r_rel, len)` gives per-segment thickness, and `color` accepts a vector — one
`meshscatter!` call renders all three types:

| `SegmentType` | value | color | `r_rel` (relative to `0.035*SCALE`) |
| --- | --- | --- | --- |
| `TETHER` | 1 | yellow | 1.0 (thick) |
| `BRIDLE` | 2 | yellow | ~0.35 (thin) |
| `WING` | 3 | black | ~0.35 (thin) |

Radii are cosmetic; tune them on screen. If a single call turns out awkward, fall back to three
`meshscatter!` calls with three markers — same data, three index sets.

### Status text

The status-text block at the end of `update_system` (time, height, elevation, force, power, wind …)
is worth keeping for the V3 view. Factor it out of `update_system` into
`update_status_text!(kv, state; wind, height)` and call it from both paths — do not duplicate the
`@sprintf` block.

### Viewer setup for the example

- `Viewer3D(false)` — `show_kite=false`; the `data/kite.obj` mesh and the `quat`/`kite_pos`
  observables play no role, so step 1 needs no NED/quaternion handling at all.
- `scale = 0.08`, as in `test/test_parking.jl`: the kite sits at ~155 m, giving ~12.4 scene units
  against coordinate axes drawn out to ~14.6. Particle spheres (`0.07*SCALE`) stay visible.
- `set.segments` must not be consulted anywhere on the new path — it is 6 and meaningless here.

## Step 1: `examples/park_v3.jl`

Replays `data/tmp_parking.arrow` with the topology from `data/v3_segments.csv`:

```julia
set_data_path()
segments = load_segments("data/v3_segments.csv")   # n x 3 Matrix{Int}
log = load_log("tmp_parking")
viewer = Viewer3D(false)
init(viewer, segments)
for state in log.syslog
    update_segments!(viewer, state; scale=0.08)
    update_status_text!(viewer, state)
    wait_until(...)   # Timers, as in test_parking.jl
end
```

- Real-time playback at the log's 60 Hz; keep a `TIME_LAPSE_RATIO` constant (as the other examples
  do) so every n-th frame can be drawn if 60 Hz proves too fast for GLMakie here.
- Honour `viewer.btn_PLAY`/`btn_STOP` the way `examples/depower_simple.jl` does, so the replay can
  be paused.
- `__init__` points the data path at `./data` only when run from the repo root — the example must
  state that, like the others.

### Acceptance for step 1

- Tether renders as one thick yellow strand from (0,0,0) to the bridle point, the bridle as thin
  yellow lines, the wing outline as thin black lines, 44 spheres at the points.
- The kite hangs at ~70° elevation, roughly still (it is a parking run), for the full 10 s.
- No `BoundsError`, and the one-point/four-point examples (`basic_1p.jl`, `basic_4p.jl`,
  `test/runtests.jl`) still behave exactly as before.

## Step 2 (after step 1 looks right)

- Add `park_v3.jl` to `examples/menu.jl`.
- Add `tmp_parking.arrow` and `v3_segments.csv` to the file list in `copy_viewer_settings` so the
  example also runs after `install_examples()`.
- `CHANGELOG.md` under `## Unreleased`: new example plus the new exported functions.
- Consider a headless smoke test (the CI runs under `xvfb-run`) that replays ~10 frames and checks
  the observable lengths — cheap, and it would have caught the `BoundsError` above.

## Decisions (all settled)

1. **The reusable functions go into `src/`**, as described under "Where the code goes";
   `examples/park_v3.jl` stays a thin driver. The rejected alternative was to build the
   observables and `meshscatter!` layers inside the example on `viewer.scene3D` — faster to get on
   screen, but it leaves nothing behind for a live V3 simulation view.
2. **The topology arrives as a plain integer matrix.** Reading a `SystemStructure` is ruled out —
   it would make KiteViewers depend on `SymbolicAWEModels`. `init(kv, segments)` takes the
   `n × 3` `Matrix{Int}` described above, with the segment type encoded numerically, so a caller
   that *does* know about `SystemStructure` can build the matrix itself. `v3_segments.csv` stays a
   fixture for the example, loaded by `load_segments`.
3. **The point/segment wireframe is the intended look**, so the 288 VSM panel corners in slots
   `45:332` are simply ignored. Rendering the panels the way `SymbolicAWEModelsMakieExt` does is
   not part of this work.
