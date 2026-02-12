using Pkg, Timers
if ! ("KiteModels" ∈ keys(Pkg.project().dependencies))
    Pkg.activate("examples")
end

using KiteViewers, KiteModels

# example program that shows
# a. how to create a video
# b. how to create a performance plot (simulation speed vs time)

set = deepcopy(load_settings("system.yaml"))
# set.solver = "IDA"

kcu::KCU = KCU(set)
kps4::KPS4 = KPS4(kcu)

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME = 45
TIME_LAPSE_RATIO = 2
STEPS = Int64(round(TIME/dt))
STATISTIC = false
SHOW_KITE = false
SAVE_PNG  = false
const PLOT_PERFORMANCE = false
# end of user parameter section #

time_vec::Vector{Float64} = zeros(div(STEPS, TIME_LAPSE_RATIO))
viewer::Viewer3D = Viewer3D(SHOW_KITE)

# ffmpeg -r:v 20 -i "video%06d.png" -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 10 -an "video.mp4"
# plot(range(0.5,45,step=0.5), time_vec, ylabel="CPU time [%]", xlabel="Simulation time [s]", legend=false)

function update_system2(kps)
    sys_state = SysState(kps)
    KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3.5)
end 

function simulate(integrator, steps; log=false)
    start = integrator.p.iter
    start_time_ns = time_ns()
    time_ = 0.0
    clear_viewer(viewer; stop_=false)
    for i in 1:steps
        iter = kps4.iter
        if i == 300
            set_depower_steering(kps4.kcu, 0.25, 0.1)
        elseif i == 302
            set_depower_steering(kps4.kcu, 0.25, -0.1)
        elseif i == 304
            set_depower_steering(kps4.kcu, 0.25, 0.0)    
        elseif i == 350
             set_depower_steering(kps4.kcu, 0.25, -0.1)
        elseif i == 352
            set_depower_steering(kps4.kcu, 0.25, 0.0)           
        end
        # KitePodModels.on_timer(kcu, dt)
        KiteModels.next_step!(kps4, integrator; set_speed=0, dt=dt)     
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            update_system2(kps4) 
            if log
                save_png(viewer, index=div(i, TIME_LAPSE_RATIO))
            end
            wait_until(start_time_ns + dt*1e9, always_sleep=true) 
            start_time_ns = time_ns()
            time_vec[div(i, TIME_LAPSE_RATIO)]=time_/(TIME_LAPSE_RATIO*dt)*100.0
            time_ = 0.0
        end
        time_ += (kps4.iter - iter)*1.5e-6
    end
    (integrator.p.iter - start) / steps
end

integrator = KiteModels.init!(kps4; delta=0.0, stiffness_factor=0.5, prn=STATISTIC)

av_steps = simulate(integrator, STEPS, log=SAVE_PNG)
if PLOT_PERFORMANCE
    using ControlPlots: plot
    plot(range(0.1,TIME,step=0.1), time_vec; ylabel="CPU time [%]", xlabel="Simulation time [s]")
end
