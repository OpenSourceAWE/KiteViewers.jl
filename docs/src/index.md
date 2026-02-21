```@meta
CurrentModule = KiteViewers
```
# KiteViewers.jl

This package provides different kinds of 2D and 3D viewers for kite power systems.

It is part of Julia Kite Power Tools, which consists of the following packages:

![Kite Power Tools](kite_power_tools.png)

## What to install

If you want to run simulations and see the results in 3D, please install the meta package
[KiteSimulators](https://github.com/aenarete/KiteSimulators.jl). If you just want to replay
log files or implement a real-time viewer for a system outside of Julia, this package will be
sufficient. When you have KiteSimulators installed, please replace any statement
`using KiteViewers` in the examples with `using KiteSimulators`.

## Installation

Download and install [Julia 1.10](https://ufechner7.github.io/2024/08/09/installing-julia-with-juliaup.html)
or later, if you haven't already. Make sure you have the package `TestEnv` in your global
environment if you want to run the examples. If you are not sure, run:

```bash
julia -e 'using Pkg; Pkg.add("TestEnv")'
```

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

## Examples

```julia
using KiteViewers
viewer = Viewer3D(true);
```

After some time a window with the 3D view of a kite power system should pop up.
If you keep the window open and execute the following code:

```julia
using KiteUtils
segments = 6
state = demo_state(segments + 1)
update_system(viewer, state)
```

you should see a kite on a tether.

The same example, but using the 4 point kite model:

```julia
using KiteViewers, KiteUtils
viewer = Viewer3D(true);
segments = 6
state = demo_state_4p(segments + 1)
update_system(viewer, state, kite_scale=0.25)
```

You can find more examples in the folder `examples`.

## Advanced usage

For more examples see: [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl)

## See also

- [Research Fechner](https://research.tudelft.nl/en/publications/?search=Uwe+Fechner&pageSize=50&ordering=rating&descending=true) for the scientific background of this code
- The meta-package [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl)
- The packages [KiteModels](https://github.com/ufechner7/KiteModels.jl), [WinchModels](https://github.com/OpenSourceAWE/WinchModels.jl), [KitePodModels](https://github.com/OpenSourceAWE/KitePodModels.jl) and [AtmosphericModels](https://github.com/OpenSourceAWE/AtmosphericModels.jl)
- The packages [KiteUtils](https://github.com/ufechner7/KiteUtils.jl) and [KiteControllers](https://github.com/OpenSourceAWE/KiteControllers.jl)
