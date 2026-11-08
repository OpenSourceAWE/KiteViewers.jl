```@meta
CurrentModule = KiteViewers
```

# API Reference

## Types

```@docs
AbstractKiteViewer
AKV
Viewer3D
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
KiteViewers.set_title!
KiteViewers.copy_examples
KiteViewers.create_coordinate_system
KiteViewers.axis_arrowhead!
KiteViewers.sphere_mesh
```

## Drawing a system definition

Draws the points and segments of a `KiteGeometry.SystemDefinition`, for a kite log (e.g. from
`SymbolicAWEModels`/`V3Kite`) that does not fit the built-in one-point/four-point/three-line kite
models — see `examples/park_v3.jl`. `KiteGeometry` is reexported, so `load_structure` reads one.

```@docs
init_segments
update_segments!
KiteViewers.draw_segments!
KiteViewers.segment_kinds
KiteViewers.segment_radius
KiteViewers.segment_points
KiteViewers.canopy_triangles
KiteViewers.segment_geometry
```

## Deprecated

A matrix of segments still draws through [`init_segments`](@ref) on the same path as a definition.

```@docs
SegmentType
load_segments
KiteViewers.matrix_definition
KiteViewers.row_kind
```
