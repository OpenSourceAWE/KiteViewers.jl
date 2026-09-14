using KiteViewers, Test

set_data_path()

@testset "a KS attitude is drawn the same way round as the KA one" begin
    viewer::Viewer3D = Viewer3D(false)
    state = demo_state(se().segments + 1)
    update_system(viewer, state)
    quat_KA = KiteViewers.quat[]
    state.orient .= fromKA2KS(state.orient)
    update_system(viewer, state; frame=KS)
    @test KiteViewers.quat[] ≈ quat_KA atol=1e-6
end
