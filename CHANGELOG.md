# Changelog

## KiteViewers v0.6.0 13-08-2026
### Added
- `bin/release`, posting release notes to GitHub issue #13 to trigger JuliaRegistrator; checks
  that both `Manifest-v1.11.toml` and `Manifest-v1.12.toml` match their `.default` counterparts
  and that the `Project.toml`/`CHANGELOG.md` versions agree before prompting to release
- example `menus_4p.jl`
- example `park_v3.jl`, replaying a V3 kite log against an arbitrary point/segment topology
  (tether/bridle/wing, thick/thin, yellow/black); new functions `init_segments`, `load_segments`,
  `update_segments!`, `update_status_text!`, and the `SegmentType` enum
- `kite_scale` keyword of `update_segments!`, enlarging bridle and wing about the end of the main
  tether so the kite stays visible next to a long tether
- main tether of a segment topology drawn half as thick, with a bead on each sub-segment
  endpoint so its segmentation stays readable
- `data/v3_segments.csv` (the V3 kite's 44-point topology) and `data/tmp_parking.arrow` (the
  sample parking log), the two inputs `park_v3.jl` needs; it requires neither KiteModels nor
  SymbolicAWEModels
- `Viewer3D` fields `seg_topology`, `wing_positions`, `wing_markersizes`, `wing_rotation` and
  `point_positions`, backing the segment-topology rendering; all `nothing` until `init_segments` is called
- `workflow_dispatch` trigger of the CI workflow
- `park_v3` entry in the interactive `menu()`
### Changed
- BREAKING: update KiteUtils to 0.11.13 (needed to read the newer `Qw/Qx/Qy/Qz` log format)
- render at `px_per_unit=2` by default (supersampled), smoothing the thin tether/segment
  cylinders; configurable via the new `Viewer3D(...; px_per_unit)` keyword
- replaced ControlPlots with MakieControlPlots in the examples project and the examples;
  `plt.savefig(name)` becomes `savefig(name)`, which exports the figure last displayed (so it
  must follow `display(p)`) and writes into `output/`. The examples project therefore needs
  Julia 1.11+ and GLMakie 0.12+; `install_examples()` installs MakieControlPlots too
- `bin/run_julia` forwards its arguments to julia, with and without a system image

## KiteViewers v0.5.2 15-03-2026
### Changed
- fix startup artifact, zoom is now correct from the beginning
- fix examples
- update `install` script

## KiteViewers v0.5.1 01-03-2026
### Changed
- now tested on MacOS, adjusted text position and font for MacOS
- fix JETLS warnings

### Added
- function bring_viewer_to_front(); Mac only, does nothing otherwise
- function reactivate_host_app();   Mac only, does nothing otherwise

## KiteViewers v0.5.0 12-02-2026
### Changed
- BREAKING: update KiteUtils to 1.11.2
- use a workspace "examples" instead of TestEnv -> min Julia version now 1.11
- update examples
- bump GLMakie to 0.13
- update README.md
- update CI.yml
- update script `update_manifest.jl`
### Added
- add Manifest-v1.11.toml.default
- add Manifest-v1.12.toml.default

## KiteViewers v0.4.24 01-06-2025
### Changed
- bump GLMakie to 0.11
- bump GeometryBasic to 0.5

## KiteViewers v0.4.23 05-05-2025
### Changed
- bumped KiteUtils to `1.10.5`
- bumped KiteModels to `0.7.3`
- adapted the code to be able to process the new arrays in SysState

## KiteViewers v0.4.22 20-04-2025
### Changed
- update KiteUtils to `1.10.2`
- removed example `basic_4p_3lines.jl`

## KiteViewers v0.4.21 17-11-2024
### Fixed
- fix display of kite in `KPS_3L` model
- make `menu()` work
### Changed
- reexport `KiteUtils`
- automatically execute `using KiteViewers` when starting Julia with `./bin/run_julia`
- improved the script `bin/install`

## KiteViewers v0.4.20 09-11-2024
### Fixed
- fix display of kite in one point model
- fix function `save_png(viewer)`; it uses the folder `video` as output now
### Changed
- now v_wind_200m and v_wind_kite are displayed as default
- update_system has now the optional parameter wind=[:v_wind_gnd, :v_wind_200m, :v_wind_kite]
- the orientation of the one point kite is now converted by default
- rename `reelout.jl` to `reelout_4p.jl`
- improve installation instructions
### Added
- add function `install_examples()`
- add example `reelout_1p.jl`

## KiteViewers v0.4.19 20-10-2024
### Changed
- bump KiteUtils to 0.8.2
- add param `ned=true` to function `update_system()`; with this parameter
  the orientation is automatically converted from **NED** to **viewer** reference frame
- fix the example `basic_4p.jl`

## KiteViewers v0.4.18 16-10-2024
### Changed
- bump KiteUtils to 0.8

## KiteViewers v0.4.17 25-08-2024
### Changed
- replaced Plots with ControlPlots in Project.toml and the examples
- deleted obsolete files, e.g. plots.jl
- fix examples
### Added
- add support for 3-line kite
- add WAIVER from Delft University to README.md
- add menu.jl
### Fixed
- fix tests

## KiteViewers v0.4.16 28-07-2024
### Fixed
- bugfix in function clear_viewer(), rename parameter `stop` to `stop_`

## KiteViewers v0.4.15 28-07-2024
### Changed
- add optional, boolean parameter `stop` to the function clear_viewer()
- update KiteUtils to 0.7
- add example show_messages.jl that receives html messages
- fix the older examples

## KiteViewers v0.4.14 15-07-2024
### Changed
- upgrade to GLMakie 0.10
- improve example reelout.jl

## KiteViewers v0.4.13 08-07-2024
### Changed
- fix pre-compilation on Ubuntu 24.04
- replace `test_sterring.jl` with `test_parking.jl`
- fix tests
- smaller font size on Windows

## KiteViewers v0.4.12 30-04-2024
### Added
- add menu_project for loading, saving and editing projects

## KiteViewers v0.4.11 05-04-2024
### Added
- add menu time_lapse for changing the simulation/ replay speed
- add field `mod_text` to Viewer3D; it defines the quotient of the update rate and the text update rate
- add textbox `t_sim` to enter the simulation time

## KiteViewers v0.4.10 30-03-2024
### Fixed
- fixed bug that caused problems with displaying tethers with more than 6 segments

### Added
- the function Viewer3D() has now the optional parameter `menus=true`, if passed it shows the menus, otherwise not



