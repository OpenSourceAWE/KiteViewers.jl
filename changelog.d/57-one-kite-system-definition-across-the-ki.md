### Changed
- BREAKING: `init_segments` takes a KiteGeometry `SystemDefinition` in place of a segment matrix;
  a segment is drawn as tether, wing or bridle from the definition's tethers, stations and canopy
  faces. `load_segments`, `SegmentType`/`TETHER`/`BRIDLE`/`WING` and `data/v3_segments.csv` are
  gone; `examples/park_v3.jl` reads `data/v3_structure.yml`, the V3 kite's structure document.
- BREAKING: the `Viewer3D` field `seg_topology` is now `definition`.
- `KiteGeometry` is reexported beside `KiteUtils`.
- `bin/install` accepts Julia 1.13, with its own `Manifest-v1.13.toml.default`.
