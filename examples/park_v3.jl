using KiteViewers, KiteUtils
using Timers: wait_until

# Replays the V3 parking log `data/tmp_parking.arrow`, drawn from KiteGeometry's V3 document.
# Run it from the repository root; it needs no simulation package.

TIME_LAPSE_RATIO = 1 # 1 = real time; N = N times faster, drawing every N-th log row

# strict=false drops the pulley efficiency of a SymbolicAWEModels pulley model
v3_structure = joinpath(pkgdir(KiteGeometry), "test", "data", "v3_psm_structure.yml")
definition = load_structure(v3_structure; strict=false)
log = load_log("tmp_parking")
dt::Float64 = log.syslog[2].time - log.syslog[1].time

viewer::Viewer3D = Viewer3D(false)
init_segments(viewer, definition)

# true while a replay runs; the built-in RUN/PAUSE handler flips `viewer.stop` on every click
replaying = Ref(false)

function replay()
    replaying[] = true
    viewer.stop = false
    clear_viewer(viewer; stop_=false)
    bring_viewer_to_front()
    start_time_ns = time_ns()
    for (i, state) in enumerate(log.syslog)
        viewer.stop && break
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == length(log.syslog)
            update_segments!(viewer, state; scale=0.08, kite_scale=2.0)
            update_status_text!(viewer, state; height=state.Z[1])
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            # wait_until ends in a busy-spin; without yield the window stops responding
            yield()
            start_time_ns = time_ns()
        end
    end
    replaying[] = false
    stop(viewer)
end

on(viewer.btn_PLAY.clicks) do _
    # during a replay the built-in handler has already paused it
    if !replaying[]
        @async replay()
    end
end
on(viewer.btn_STOP.clicks) do _
    stop(viewer)
end

replay()
nothing
