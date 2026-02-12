let
    using KiteViewers, KiteModels, KitePodModels, Rotations, StaticArrays, Plots, Timers

    # change this to KPS3 or KPS4
    Model = KPS4

    if ! @isdefined kcu;  kcu = KCU(se());   end
    if ! @isdefined kps4; kps4 = Model(kcu); end

    # the following values can be changed to match your interest
    dt = 0.05
    TIME = 0.25
    TIME_LAPSE_RATIO = 5
    STEPS = Int64(round(TIME/dt))
    FRONT_VIEW = false
    ZOOM = true
    STATISTIC = false
    SHOW_KITE = true
    # end of user parameter section #

    viewer = Viewer3D(SHOW_KITE)

    function update_system2(kps)
        sys_state = SysState(kps)
        KiteViewers.update_system(viewer, sys_state; scale = 0.08, kite_scale=3)
    end 

    function simulate(integrator, steps)
        start = integrator.p.iter
        start_time_ns = time_ns()
        for i in 1:steps
            if i == 300
                set_depower_steering(kps4.kcu, 0.25, 0.1)
            elseif i == 302
                set_depower_steering(kps4.kcu, 0.25, -0.1)
            elseif i == 304
                set_depower_steering(kps4.kcu, 0.25, 0.0)            
            end
            # KitePodModels.on_timer(kcu, dt)
            KiteModels.next_step!(kps4, integrator; set_speed=0, dt=dt)     
            update_system2(kps4)
            # sleep(dt/5)    
            wait_until(start_time_ns+i*dt/TIME_LAPSE_RATIO*1e9)     
        end
        (integrator.p.iter - start) / steps
    end

    integrator = KiteModels.init!(kps4, stiffness_factor=0.5, prn=STATISTIC)

    av_steps = simulate(integrator, STEPS)
    plot(1:10)
end

@info "Precompile script has completed execution."