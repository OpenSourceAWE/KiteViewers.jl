# Changelog
### KiteViewers v0.5 - 2026-02-12
#### Changes
- BREAKING: update KiteUtils to 1.11.2
- use a workspace "examples" instead of TestEnv -> min Julia version now 1.11
- update examples
- bump GLMakie to 0.13
- update README.md
- update CI.yml
- update script `update_manifest.jl`
#### Added
- add Manifest-v1.11.toml.default
- add Manifest-v1.12.toml.default

### KiteViewers v0.4.24 - 2025-01-06
#### Changed
- bump GLMakie to 0.11
- bump GeometryBasic to 0.5

### KiteViewers v0.4.23 - 2025-05-05
#### Changed
- bumped KiteUtils to `1.10.5`
- bumped KiteModels to `0.7.3`
- adapted the code to be able to process the new arrays in SysState

### KiteViewers v0.4.22 - 2025-04-20
#### Changed
- update KiteUtils to `1.10.2`
- removed example `basic_4p_3lines.jl`

### KiteViewers v0.4.21 - 2024-11-17
#### Fixed
- fix display of kite in `KPS_3L` model
- make `menu()` work
#### Changed
- reexport `KiteUtils`
- automatically execute `using KiteViewers` when starting Julia with `./bin/run_julia`
- improved the script `bin/install`

### KiteViewers v0.4.20 - 2024-11-09
#### Fixed
- fix display of kite in one point model
- fix function `save_png(viewer)`; it uses the folder `video` as output now
#### Changed
- now v_wind_200m and v_wind_kite are displayed as default
- update_system has now the optional parameter wind=[:v_wind_gnd, :v_wind_200m, :v_wind_kite]
#### Added
- add function `install_examples()`
- add example `reelout_1p.jl`

### KiteViewers v0.4.19 - 2024-10-20
#### Changed
- bump KiteUtils to 0.8.2
- add param `ned=true` to function `update_system()`; with this parameter
  the orientation is automatically converted from **NED** to **viewer** reference frame
- fix the example `basic_4p.jl`

### KiteViewers v0.4.18 - 2024-10-16
#### Changed
- bump KiteUtils to 0.8

### KiteViewers v0.4.17 - 2024-08-25
#### Changed
- replaced Plots with ControlPlots in Project.toml and the examples
- deleted obsolete files, e.g. plots.jl
- fix examples
#### Added
- add support for 3-line kite
- add WAIVER from Delft University to README.md
- add menu.jl
#### Fixed
- fix tests

### KiteViewers v0.4.16 - 2024-07-28
- bugfix in function clear_viewer(), rename parameter `stop` to `stop_`

### KiteViewers v0.4.15 - 2024-07-28
#### Changed
- add optional, boolean parameter `stop` to the function clear_viewer()
- update KiteUtils to 0.7
- add example show_messages.jl that receives html messages
- fix the older examples

### KiteViewers v0.4.14 - 2024-07-15
#### Changed
- upgrade to GLMakie 0.10
- improve example reelout.jl

### Unreleased
#### Changed
- the orientation of the one point kite is now converted by default
- add example `reelout_1p.jl`
- rename `reelout.jl` to `reelout_4p.jl`
- improve installation instructions

### KiteViewers v0.4.13 - 2024-07-08
#### Changed
- fix pre-compilation on Ubuntu 24.04
- replace `test_sterring.jl` with `test_parking.jl`
- fix tests
- smaller font size on Windows

### KiteViewers v0.4.12 - 2024-04-30
#### Added
- add menu_project for loading, saving and editing projects

### KiteViewers v0.4.11 - 2024-04-05
#### Added
- add menu time_lapse for changing the simulation/ replay speed
- add field `mod_text` to Viewer3D; it defines the quotient of the update rate and the text update rate
- add textbox `t_sim` to enter the simulation time

### KiteViewers v0.4.10 - 2024-03-30
#### Fixed
- fixed bug that caused problems with displaying tethers with more than 6 segments

#### Added
- the function Viewer3D() has now the optional parameter `menus=true`, if passed it shows the menus, otherwise not



