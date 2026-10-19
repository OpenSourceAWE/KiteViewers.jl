# activate the test environment if needed
using Pkg
if dirname(Pkg.project().path) != @__DIR__
    Pkg.activate(@__DIR__)
end
using KiteViewers, Test

set_data_path()

# The viewer state (quat, textnode, ...) is module-global, so all test files share one Viewer3D
if !@isdefined(viewer) || !isopen(viewer.screen)
    viewer::Viewer3D = Viewer3D(false)
end

@testset "a KS attitude is drawn the same way round as the KA one" begin
    set_title!(viewer, Test.get_testset().description)
    state = demo_state(se().segments + 1)
    attitudes_KA = [[0.70710677, -0.70710677, 0, 0], [1, 0, 0, 0], [0.5, 0.5, 0.5, 0.5],
                    [0.5, -0.5, 0.5, -0.5], [0.6, 0.8, 0, 0]]
    for attitude in attitudes_KA
        state.orient .= attitude
        update_system(viewer, state)
        drawn_from_KA = KiteViewers.quat[]
        state.orient .= fromKA2KS(attitude)
        update_system(viewer, state; frame=KS)
        @test KiteViewers.quat[] ≈ drawn_from_KA atol=1e-6
    end
end
