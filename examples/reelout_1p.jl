using Pkg, Timers
if ! ("KiteModels" ∈ keys(Pkg.project().dependencies))
    Pkg.activate("examples")
end

using KiteViewers, KiteModels

# example program that shows
# a. how to create a performance plot (simulation speed vs time)

set = load_settings("system.yaml")
set.abs_tol=0.00006
set.rel_tol=0.0001 
kcu::KCU = KCU(deepcopy(set))
kps3::KPS3 = KPS3(kcu)

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME = 50
TIME_LAPSE_RATIO = 5
STEPS = Int64(round(TIME/dt))
STATISTIC = false
SHOW_VIEWER = true
SHOW_KITE = true
SAVE_PNG  = false
PLOT_PERFORMANCE = true
# end of user parameter section #

time_vec::Vector{Float64} = zeros(div(STEPS, TIME_LAPSE_RATIO))
viewer::Viewer3D = Viewer3D(SHOW_KITE)

# ffmpeg -r:v 20 -i "video%06d.png" -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 10 -an "video.mp4"

function update_system2(kps)
     sys_state = SysState(kps)
     KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3.0)
end 

function simulate(integrator, steps; log=false)
    start = integrator.p.iter
    start_time_ns = time_ns()
    time_ = 0.0
    v_ro = 0.0
    acc = 0.1
    clear_viewer(viewer; stop_=false)
    for i in 1:steps
        iter = kps3.iter
        if i > 300
            v_ro += acc*dt
        end
        KiteModels.next_step!(kps3, integrator; set_speed=v_ro, dt=dt)     
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            time_ = time_ns()-start_time_ns
            if SHOW_VIEWER update_system2(kps3) end
            if log
                save_png(viewer, index=div(i, TIME_LAPSE_RATIO))
            end
            if SHOW_VIEWER
                wait_until(start_time_ns+dt*1e9, always_sleep=true) 
            end
            if i == 1
                time_ = 0.0
            end
            start_time_ns = time_ns()
            time_vec[div(i, TIME_LAPSE_RATIO)]=1e-9*time_/(TIME_LAPSE_RATIO*dt)*100.0
            time_ = 0.0
        end
        # if mod(i, TIME_LAPSE_RATIO) == 0 
        #     break
        # end
    end
    (integrator.p.iter - start) / steps
end

integrator = KiteModels.init!(kps3, delta=0, stiffness_factor=0.8, prn=STATISTIC)

av_steps = simulate(integrator, STEPS, log=SAVE_PNG)
if PLOT_PERFORMANCE
    using ControlPlots
    p = plot(range(0.25,TIME,step=0.25), time_vec; ylabel="CPU time [%]", xlabel="Simulation time [s]")
    plt.savefig("performance.png")
    display(p)
end
# mean with :Dense integrator: 6.66% CPU time,  15 times realtime
# mean with :GMRES integrator: 1.96% CPU time,  51 times realtime
# mean with DFBDF solver:      0.28% CPU time, 352 times realtime on Ryzen laptop
