using KiteViewers, LinearAlgebra, Test

set_data_path(joinpath(dirname(@__DIR__), "data"))

@testset "the V3 definition draws each segment as its tether, wing or bridle" begin
    definition = load_structure(joinpath(get_data_path(), "v3_structure.yml"))
    state = load_log("tmp_parking"; frame=KS).syslog[1]
    viewer::Viewer3D = Viewer3D(false)
    init_segments(viewer, definition)
    update_segments!(viewer, state)

    point(i) = KiteViewers.Point3f(state.X[i], state.Y[i], state.Z[i])
    midpoint(segment) = (point(segment.points[1]) + point(segment.points[2])) / 2
    is_wing(segment) = all(>=(2), segment.points) && all(<=(21), segment.points)
    tether = definition.segments[definition.tethers[1].segments]
    wing = filter(is_wing, definition.segments)
    tether_and_bridle = filter(!is_wing, definition.segments)
    @test (length(tether), length(wing), length(tether_and_bridle)) == (6, 46, 49)
    @test viewer.wing_positions[] ≈ midpoint.(wing)
    @test viewer.positions[] ≈ midpoint.(tether_and_bridle)
    tether_radius = maximum(size[1] for size in viewer.markersizes[])
    @test [size[1] == tether_radius for size in viewer.markersizes[]] ==
          [segment in tether for segment in tether_and_bridle]
    @test viewer.point_positions[] ≈ point.(1:44)
end

@testset "every KiteGeometry name reaches a caller of KiteViewers" begin
    @test filter(name -> !isdefined(KiteViewers, name), names(KiteGeometry)) == Symbol[]
end
