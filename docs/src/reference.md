```@meta
CurrentModule = KiteViewers
```

# API Reference

## Types

```@docs
AbstractKiteViewer
AKV
Viewer3D
SegmentType
```

## Functions

```@docs
clear_viewer
update_system
update_status_text!
KiteViewers.save_png
KiteViewers.stop
KiteViewers.pause
KiteViewers.set_status
KiteViewers.copy_examples
```

## Arbitrary point/segment topologies

Used to replay a kite log (e.g. from `SymbolicAWEModels`/`V3Kite`) that does not fit the built-in
one-point/four-point/three-line kite models — see `examples/park_v3.jl`.

```@docs
init_segments
load_segments
update_segments!
KiteViewers.segment_geometry
```
