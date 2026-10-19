# activate the test environment if needed
using Pkg
if dirname(Pkg.project().path) != @__DIR__
    Pkg.activate(@__DIR__)
end
using KiteViewers, Test
using KiteViewers: Point3f, norm

set_data_path()

# The viewer state (quat, textnode, ...) is module-global, so all test files share one Viewer3D
if !@isdefined(viewer) || !isopen(viewer.screen)
    viewer::Viewer3D = Viewer3D(false)
end

"""
    demo_state_3l(segments)

State of a three-line kite in the layout `update_system` expects: for each of the `segments+1`
tether nodes the points of the left, right and middle line, then the left and right wing tip
and the top of the kite. The three lines start at the same ground station and follow the
tether of `demo_state`; the steering lines spread apart towards the kite.
"""
function demo_state_3l(segments)
    line = demo_state(segments + 1)
    state = demo_state(3segments + 6)
    for k in 0:segments
        dy = 0.5 * k / segments
        for (j, offset) in enumerate((-dy, dy, 0.0)) # left, right, middle line
            state.X[3k+j] = line.X[k+1]
            state.Y[3k+j] = line.Y[k+1] + offset
            state.Z[3k+j] = line.Z[k+1]
        end
    end
    # the wing is arched: the tips hang down and back, the top of the kite is ahead of them
    for (j, (dx, dy, dz)) in enumerate(((-0.4, -0.9, 0.3), (-0.4, 0.9, 0.3), (0.6, 0.0, 1.6)))
        state.X[3segments+3+j] = line.X[end] + dx
        state.Y[3segments+3+j] = line.Y[end] + dy
        state.Z[3segments+3+j] = line.Z[end] + dz
    end
    state
end

@testset "three-line kite" begin
    set_title!(viewer, Test.get_testset().description)
    @test viewer.screen.config.title == "three-line kite"
    segments = se().segments
    state = demo_state_3l(segments)
    update_system(viewer, state; kite_scale=2.0)
    # the three lines start at the same point
    @test viewer.points[1] ≈ viewer.points[2] ≈ viewer.points[3]
    @test length(viewer.part_positions[]) == 3segments + 6
    @test length(viewer.positions[]) == 3segments + 6
    @test all(p -> all(isfinite, p), viewer.positions[])
    @test all(isfinite, KiteViewers.kite_pos[])
end

@testset "status text" begin
    set_title!(viewer, Test.get_testset().description)
    state = demo_state(se().segments + 1)
    viewer.step = 0 # the step is incremented before the text is updated every `mod_text` steps
    update_status_text!(viewer, state; wind=[:v_wind_gnd, :v_wind_200m, :v_wind_kite])
    @test viewer.step == 1
    @test occursin("time:", KiteViewers.textnode[])
    @test occursin("wind_gnd:", KiteViewers.textnode2[])
    @test occursin("wind@200m:", KiteViewers.textnode2[])
    @test occursin("wind@kite:", KiteViewers.textnode2[])
end

@testset "buttons and controls" begin
    set_title!(viewer, Test.get_testset().description)
    viewer.btn_RESET.clicks[] += 1
    @test KiteViewers.zoom[1] == 1.0
    viewer.btn_ZOOM_in.clicks[] += 1
    @test KiteViewers.zoom[1] ≈ 1.2
    viewer.btn_ZOOM_out.clicks[] += 1
    @test KiteViewers.zoom[1] ≈ 1.0

    set_status(viewer, "Running")
    pause(viewer)
    @test KiteViewers.status[] == "Paused"
    @test KiteViewers.last_status == "Running"
    @test viewer.stop

    viewer.btn_PLAY.clicks[] += 1 # resumes with the status saved by `pause`
    @test KiteViewers.running[]
    @test KiteViewers.status[] == "Running"
    @test !viewer.stop
    viewer.btn_PLAY.clicks[] += 1
    @test !KiteViewers.running[]
    @test KiteViewers.status[] == "Paused"

    viewer.btn_STOP.clicks[] += 1
    @test KiteViewers.status[] == "Stopped"

    viewer.step, viewer.energy = 10, 5.0
    set_status(viewer, "Running")
    clear_viewer(viewer; stop_=false)
    @test viewer.step == 1
    @test viewer.energy == 0
    @test KiteViewers.status[] == "Running"
    clear_viewer(viewer)
    @test KiteViewers.status[] == "Stopped"
    @test !KiteViewers.running[]
end

@testset "save_png" begin
    set_title!(viewer, Test.get_testset().description)
    mktempdir() do dir
        cd(dir) do
            save_png(viewer; filename="frame", index=7)
            @test isfile(joinpath("video", "frame000007.png"))
            @test viewer.screen.config.title == "save_png" # saving doesn't reset the title
        end
    end
end

@testset "install_examples" begin
    data_path = get_data_path()
    mktempdir() do dir
        cd(dir) do
            KiteViewers.install_examples(false)
            @test isfile(joinpath("examples", "park_v3.jl"))
            @test isfile(joinpath("data", "kite.obj"))
            @test isfile(joinpath(get_data_path(), "system.yaml"))
        end
    end
    set_data_path(data_path)
    @test isnothing(KiteViewers.reactivate_host_app()) # also exported by KiteModels
    @test isnothing(KiteViewers.bring_viewer_to_front())
end

@testset "viewer with menus" begin
    # A second viewer, as init_segments changes the layers of the viewer it is called on.
    # It is created last: GLMakie shows it in the window of the shared viewer.
    global viewer_menus = Viewer3D(se(), false; menus=true)
    set_title!(viewer_menus, Test.get_testset().description)
    # draw a four-point kite instead of the placeholder tether of a new viewer
    segments = se().segments
    update_system(viewer_menus, demo_state_4p(segments + 1); kite_scale=0.25)
    @test length(viewer_menus.part_positions[]) == segments + 5
    @test !isnothing(viewer_menus.menu)
    @test !isnothing(viewer_menus.menu_rel_tol)
    @test !isnothing(viewer_menus.menu_time_lapse)
    @test !isnothing(viewer_menus.menu_project)
    @test !isnothing(viewer_menus.t_sim)
    @test !isnothing(viewer_menus.btn_OK)
end

# the V3 definition and log are only in the data folder of KiteViewers, not in the one of KiteUtils
const VIEWER_DATA = joinpath(dirname(@__DIR__), "data")

@testset "the V3 definition draws each segment as its tether, wing or bridle" begin
    set_title!(viewer_menus, Test.get_testset().description)
    definition = load_structure(joinpath(VIEWER_DATA, "v3_structure.yml"))
    init_segments(viewer_menus, definition)
    @test length(viewer_menus.points) == 44
    @test isempty(viewer_menus.part_positions[])

    state = load_log("tmp_parking"; path=VIEWER_DATA, frame=KS).syslog[1]
    scale = 0.08
    unscaled(i) = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
    midpoint(segment) = (unscaled(segment.points[1]) + unscaled(segment.points[2])) / 2
    kinds = KiteViewers.segment_kinds(definition)
    @test [count(==(kind), kinds) for kind in (:tether, :wing, :bridle)] == [6, 46, 43]
    @test findall(==(:tether), kinds) == definition.tethers[1].segments
    @test all(all(in(2:21), segment.points) == (kind == :wing)
              for (segment, kind) in zip(definition.segments, kinds))
    tether = definition.segments[kinds .== :tether]
    wing = definition.segments[kinds .== :wing]
    tether_and_bridle = definition.segments[kinds .!= :wing]

    update_segments!(viewer_menus, state; scale)
    @test viewer_menus.points ≈ unscaled.(1:44)
    @test viewer_menus.point_positions[] == viewer_menus.points
    @test viewer_menus.wing_positions[] ≈ midpoint.(wing)
    @test viewer_menus.positions[] ≈ midpoint.(tether_and_bridle)
    tether_radius = maximum(size[1] for size in viewer_menus.markersizes[])
    @test [size[1] == tether_radius for size in viewer_menus.markersizes[]] ==
          [segment in tether for segment in tether_and_bridle]
    @test all(r -> norm(r) ≈ 1, viewer_menus.wing_rotation[])

    update_segments!(viewer_menus, state; scale, kite_scale=2.0)
    # the tether is not scaled, the kite is
    tether_points = unique(i for segment in tether for i in segment.points)
    @test all(viewer_menus.points[i] ≈ unscaled(i) for i in tether_points)
    kite_points = setdiff(1:44, tether_points)
    @test !all(viewer_menus.points[i] ≈ unscaled(i) for i in kite_points)
end

@testset "a definition without tether is scaled about its centroid" begin
    set_title!(viewer_menus, Test.get_testset().description)
    points = [Point(; name="p$i", pos_ENU=[i, 0, 0]) for i in 1:3]
    segments = [Segment(; name="s$i", points=(i, mod1(i + 1, 3))) for i in 1:3]
    triangle = SystemDefinition(; metadata=Metadata("triangle", "", "", "", "", 3, ""),
        points, segments, spanwise_stations=[SpanwiseStation(; name="rib", wing=1,
        points=[2, 3])], wings=[Wing(; name="wing", pos_ENU=[0, 0, 0])])
    n_plots = length(viewer_menus.scene3D.scene.plots)
    init_segments(viewer_menus, triangle)
    # the wing and point layers of the V3 definition are replaced, not kept
    @test length(viewer_menus.scene3D.scene.plots) == n_plots
    state = demo_state(3)
    update_segments!(viewer_menus, state; kite_scale=2.0)
    points = [Point3f(state.X[i], state.Y[i], state.Z[i]) for i in 1:3]
    center = sum(points) / 3
    @test all(viewer_menus.points[i] ≈ center + 2 * (points[i] - center) for i in 1:3)
    @test length(viewer_menus.positions[]) == 2
    @test length(viewer_menus.wing_positions[]) == 1
end

@testset "every KiteGeometry export reaches a caller of KiteViewers" begin
    exported = filter(name -> Base.isexported(KiteGeometry, name), names(KiteGeometry))
    @test filter(name -> !isdefined(KiteViewers, name), exported) == Symbol[]
    @test calc_heading === KiteUtils.calc_heading
end

@testset "closing the window" begin
    # don't leave the window of the last viewer open
    close(viewer_menus.screen)
    @test !isopen(viewer_menus.screen)
    @test isnothing(set_title!(viewer_menus, "closed")) # no error on a closed window
end
nothing
