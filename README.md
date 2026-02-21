# KiteViewers
[![Build Status](https://github.com/OpenSourceAWE/KiteViewers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/OpenSourceAWE/KiteViewers.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/OpenSourceAWE/KiteViewers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/OpenSourceAWE/KiteViewers.jl)

This package provides different kind of 2D and 3D viewers for kite power system.

It is part of Julia Kite Power Tools, which consist of the following packages:
<p align="center"><img src="./docs/kite_power_tools.png" width="500" /></p>

## What to install
If you want to run simulations and see the results in 3D, please install the meta package  [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl) . If you just want to replay log files
or implement a real-time viewer for a system outside of Julia this package will be sufficient. When you have KiteSimulators installed, please replace
any statement `using KiteViewers` in the examples with `using KiteSimulators`.

## Installation
Download and install [Julia 1.10](https://ufechner7.github.io/2024/08/09/installing-julia-with-juliaup.html) or later, if you haven't already.

If you don't have a project yet, create one with:
```bash
mkdir MyProject
cd MyProject
julia --project="."
```
and then add the package `KiteViewers` to your project by executing:
```julia
using Pkg
pkg"add KiteViewers"
``` 
at the Julia prompt.

You can install the examples with:
```julia
using KiteViewers
KiteViewers.install_examples()
```
and get a menu with the examples by typing:
```julia
menu()
```

You can run the unit tests with the command:
```julia
using Pkg
pkg"test KiteViewers"
```
This package should work on Linux, Windows and Mac. If you find a bug, please file an issue.

## Installation from git (for package developers)
First, fork this repository using the "Fork" button on the top of the website. Then, clone
your fork, e.g.:
```bash
git clone https://github.com/USERNAME/KiteViewers.jl
```
where you have to replace USERNAME with your github user name.
Then, run the installation script:
```bash
cd KiteViewers.jl
cd bin
./install
cd ..
```
The install script creates a version of `Manifest.toml` that works both with the normal project 
and with the test environment, needed to run the examples.
To launch Julia, type:
```bash
./bin/run_julia
```
For more comfort, add this line to your `.bashrc` file:
```bash
alias jl='./bin/run_julia'
```
Then you can launch Julia, using the `run_julia` script just by typing `jl`.

## Exported types
```julia
Viewer3D
AbstractKiteViewer
AKV
```
AKV is just the short form of AbstractKiteViewer, Viewer3D the first implementation of it.

Usage:
```julia
show_kite=true
viewer=Viewer3D(show_kite)
```

## Exported functions
```julia
clear_viewer(kv::AKV; stop_=true)
update_system(kv::AKV, state::SysState; scale=1.0, kite_scale=3.5)
save_png(kv::AKV; filename="video", index = 1)
stop(kv::AKV)
set_status(kv::AKV, status_text)
```

## Examples
```julia
using KiteViewers
viewer=Viewer3D(true);
```

After some time a window with the 3D view of a kite power system should pop up.
If you keep the window open and execute the following code:

```julia
using KiteUtils
segments=6
state=demo_state(segments+1)
update_system(viewer, state)
```

you should see a kite on a tether.
<p align="center"><img src="./kite_1p.png" width="500" /></p>

The same example, but using the 4 point kite model:

```julia
using KiteViewers, KiteUtils
viewer=Viewer3D(true);
segments=6
state=demo_state_4p(segments+1)
update_system(viewer, state, kite_scale=0.25)
```
<p align="center"><img src="./kite_4p.png" width="500" /></p>

You can find more examples in the folder examples.

## Advanced usage
For more examples see: [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl)

## License
This project is licensed under the MIT License. Please see the below WAIVER in association with the license.

## WAIVER
Technische Universiteit Delft hereby disclaims all copyright interest in the package “KiteSimulators.jl” (simulators for airborne wind energy systems) written by the Author(s).

Prof.dr. H.G.C. (Henri) Werij, Dean of Aerospace Engineering

## See also
- [Research Fechner](https://research.tudelft.nl/en/publications/?search=Uwe+Fechner&pageSize=50&ordering=rating&descending=true) for the scientic background of this code
- The meta-package  [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl)
- the packages [KiteModels](https://github.com/ufechner7/KiteModels.jl) and [WinchModels](https://github.com/OpenSourceAWE/WinchModels.jl) and [KitePodModels](https://github.com/OpenSourceAWE/KitePodModels.jl) and [AtmosphericModels](https://github.com/OpenSourceAWE/AtmosphericModels.jl)
- the package [KiteUtils](https://github.com/ufechner7/KiteUtils.jl) and [KiteControllers](https://github.com/OpenSourceAWE/KiteControllers.jl)