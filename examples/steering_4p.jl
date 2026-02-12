using Pkg, Timers
if ! ("KiteModels" ∈ keys(Pkg.project().dependencies))
    using TestEnv; TestEnv.activate()
end

using KiteViewers, KiteModels

set = deepcopy(load_settings("system.yaml"))
# set.solver = "IDA"

kcu::KCU = KCU(set)
kps4::KPS4 = KPS4(kcu)

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME = 45
TIME_LAPSE_RATIO = 5
STEPS = Int64(round(TIME/dt))
STATISTIC = false
SHOW_KITE = true
# end of user parameter section #

viewer::Viewer3D = Viewer3D(SHOW_KITE)

function update_system2(kps)
    sys_state = SysState(kps)
    KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3)
end 

function simulate(integrator, steps)
    start = integrator.p.iter
    start_time_ns = time_ns()
    clear_viewer(viewer; stop_=false)
    for i in 1:steps
        if i == 300
            set_depower_steering(kps4.kcu, 0.25, 0.1)
        elseif i == 303
            set_depower_steering(kps4.kcu, 0.25, 0.0)   
        elseif i == 500
            set_depower_steering(kps4.kcu, 0.25, -0.18)
        elseif i == 506
            set_depower_steering(kps4.kcu, 0.25, 0.0)           
        end
        # KitePodModels.on_timer(kcu, dt)
        KiteModels.next_step!(kps4, integrator; set_speed=0, dt=dt)     
        reltime = i*dt
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            update_system2(kps4) 
            wait_until(start_time_ns + 1e9*dt, always_sleep=true) 
            start_time_ns = time_ns()
        end
    end
    (integrator.p.iter - start) / steps
end

integrator = KiteModels.init!(kps4; delta=0, stiffness_factor=0.5, prn=STATISTIC)

av_steps = simulate(integrator, STEPS)
nothing
