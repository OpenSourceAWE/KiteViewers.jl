using KiteViewers, Test

set_data_path()

@testset "a KS attitude is drawn the same way round as the KA one" begin
    viewer::Viewer3D = Viewer3D(false)
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
