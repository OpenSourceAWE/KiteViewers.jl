using Pkg, Timers
tic()
if ! ("KiteModels" ∈ keys(Pkg.project().dependencies))
    Pkg.activate("examples")
end

using KiteViewers, KiteModels

set = deepcopy(load_settings("system.yaml"))

kcu::KCU = KCU(set)
kps4::KPS4 = KPS4(kcu)

# the following values can be changed to match your interest
dt::Float64 = 0.05
TIME = 35
TIME_LAPSE_RATIO = 5
STEPS = Int64(round(TIME/dt))
STATISTIC = false
SHOW_VIEWER = true
SHOW_KITE = true
const PLOT_PERFORMANCE = true
# end of user parameter section #

time_vec_gc::Vector{Float64} = zeros(STEPS)
time_vec_sim::Vector{Float64} = zeros(STEPS)
time_vec_tot::Vector{Float64} = zeros(div(STEPS, TIME_LAPSE_RATIO))
viewer::Viewer3D = Viewer3D(SHOW_KITE)

function simulate(integrator, steps)
    println("Start simulation for $steps steps")
    start = integrator.p.iter
    start_time_ns = time_ns()
    j=0; k=0
    KiteViewers.clear_viewer(viewer)
    GC.gc()
    GC.enable(false)
    max_time = 0
    for i in 1:steps
        if i == 300
            set_depower_steering(kps4.kcu, 0.30, 0.0)
        elseif i == 640
            set_depower_steering(kps4.kcu, 0.35, 0.0)    
        end
        t_sim = @elapsed KiteModels.next_step!(kps4, integrator; set_speed=0, dt=dt)
        if i==1
            t_sim = 0
        end
        t_gc = 0.0
        if t_sim < 0.08*dt
            t_gc = @elapsed GC.gc(false)
        end
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            update_system(viewer, SysState(kps4); scale = 0.08, kite_scale=3.0)
            end_time_ns = time_ns()
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            mtime = 0
            if i > 10/dt 
                # if we missed the deadline by more than 2 ms
                mtime = time_ns() - start_time_ns
                if mtime > dt*1e9 + 2e6
                    print(".")
                    j += 1
                end
                k +=1
            end
            if mtime > max_time
                max_time = mtime
            end
            time_tot = end_time_ns - start_time_ns
            start_time_ns = time_ns()
            time_vec_tot[div(i, TIME_LAPSE_RATIO)] = time_tot/1e9*1000 # calculate time in ms
        end
      
        time_vec_gc[i]=t_gc/dt*100.0
        time_vec_sim[i]=t_sim/dt*100.0
        # if viewer.stop break end
    end
    misses=j/k * 100
    println("\nMissed the deadline for $(round(misses, digits=2)) %. Max time: $(round((max_time*1e-6), digits=1)) ms")
    (integrator.p.iter - start) / steps
end

function play()
    integrator = KiteModels.init!(kps4; delta=0, stiffness_factor=0.5, prn=STATISTIC)
    simulate(integrator, STEPS)
    GC.enable(true)
end

on(viewer.btn_PLAY.clicks) do _
    if viewer.stop
        @async begin
            play()
            stop(viewer)
        end
    end
end
on(viewer.btn_STOP.clicks) do _
   stop(viewer)
end

toc()
play()
stop(viewer)
if PLOT_PERFORMANCE
    using ControlPlots
    if false
        plotx(range(dt,TIME,step=dt), time_vec_gc, time_vec_sim, time_vec_sim.+time_vec_gc;
              ylabels=["GC time","sim_time","total_time"],
              fig="depower_simple_timing")
    else
        plot(range(3*TIME_LAPSE_RATIO*dt,TIME,step=dt*TIME_LAPSE_RATIO), time_vec_tot[3:end];
              ylabel="time per frame [ms]")
    end
end
