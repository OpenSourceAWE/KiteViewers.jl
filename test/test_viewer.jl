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
    global viewer_menus = Viewer3D(se(), false; menus=true, text_fxaa=true)
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
    plots = KiteViewers.GLMakie.Makie.collect_atomic_plots(viewer_menus.fig.scene)
    @test count(p -> p isa KiteViewers.GLMakie.Text && p.fxaa[], plots) == 11
end

# the V3 topology and log are only in the data folder of KiteViewers, not in the one of KiteUtils
const VIEWER_DATA = joinpath(dirname(@__DIR__), "data")

@testset "segment topology" begin
    set_title!(viewer_menus, Test.get_testset().description)
    segments = load_segments(joinpath(VIEWER_DATA, "v3_segments.csv"))
    @test size(segments, 2) == 3
    @test all(t -> t in Int.((TETHER, BRIDLE, WING)), segments[:, 3])
    n_points = maximum(segments[:, 1:2])
    n_wing = count(==(Int(WING)), segments[:, 3])

    init_segments(viewer_menus, segments)
    @test length(viewer_menus.points) == n_points
    @test isempty(viewer_menus.part_positions[])
    @test length(viewer_menus.positions[]) == size(segments, 1) - n_wing
    @test length(viewer_menus.wing_positions[]) == n_wing

    state = load_log("tmp_parking"; path=VIEWER_DATA, frame=KS).syslog[1]
    scale = 0.08
    tether_points = unique(segments[segments[:, 3] .== Int(TETHER), 1:2])
    unscaled(i) = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
    update_segments!(viewer_menus, state; scale)
    @test all(viewer_menus.points[i] ≈ unscaled(i) for i in 1:n_points)
    update_segments!(viewer_menus, state; scale, kite_scale=2.0)
    # the tether is not scaled, the kite is
    @test all(viewer_menus.points[i] ≈ unscaled(i) for i in tether_points)
    kite_points = setdiff(1:n_points, tether_points)
    @test !all(viewer_menus.points[i] ≈ unscaled(i) for i in kite_points)
    @test viewer_menus.point_positions[] == viewer_menus.points
    @test all(m -> m[3] >= 0, viewer_menus.wing_markersizes[])
    @test all(r -> norm(r) ≈ 1, viewer_menus.wing_rotation[])
end

@testset "segment topology without tether" begin
    set_title!(viewer_menus, Test.get_testset().description)
    # without a tether the kite is scaled about the centroid of its points
    triangle = [1 2 Int(BRIDLE); 2 3 Int(WING); 3 1 Int(WING)]
    n_plots = length(viewer_menus.scene3D.scene.plots)
    init_segments(viewer_menus, triangle)
    # the wing and point layers of the V3 topology are replaced, not kept
    @test length(viewer_menus.scene3D.scene.plots) == n_plots
    state = demo_state(3)
    update_segments!(viewer_menus, state; kite_scale=2.0)
    points = [Point3f(state.X[i], state.Y[i], state.Z[i]) for i in 1:3]
    center = sum(points) / 3
    @test all(viewer_menus.points[i] ≈ center + 2 * (points[i] - center) for i in 1:3)
    @test length(viewer_menus.positions[]) == 1
    @test length(viewer_menus.wing_positions[]) == 2
end

@testset "closing the window" begin
    # don't leave the window of the last viewer open
    close(viewer_menus.screen)
    @test !isopen(viewer_menus.screen)
    @test isnothing(set_title!(viewer_menus, "closed")) # no error on a closed window
end
nothing
