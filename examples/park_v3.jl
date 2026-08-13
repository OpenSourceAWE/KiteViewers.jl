using KiteViewers, KiteUtils
using Timers: wait_until

# Replays a V3 kite parking run: `data/tmp_parking.arrow` (see PlanV3.md) driven by the point/
# segment topology in `data/v3_segments.csv`. Unlike the other examples this needs neither
# KiteModels nor SymbolicAWEModels — only the log and the topology CSV.
# Must be run from the repository root (KiteViewers' `__init__` then finds `./data` on its own).

TIME_LAPSE_RATIO = 1 # 1 = real time; N = N times faster, drawing every N-th log row

segments = load_segments(joinpath(get_data_path(), "v3_segments.csv"))
log = load_log("tmp_parking")
dt = log.syslog[2].time - log.syslog[1].time

viewer::Viewer3D = Viewer3D(false)
init_segments(viewer, segments)

# Guards against a second replay starting while one is already in flight. `viewer.stop` cannot
# serve as that guard: `Viewer3D`'s own built-in RUN/PAUSE click handler (wired up inside the
# `Viewer3D` constructor, so it always runs before the handler below) flips `viewer.stop` on
# *every* click, before this script's handler gets a look at it.
replaying = Ref(false)

function replay()
    replaying[] = true
    viewer.stop = false
    clear_viewer(viewer; stop_=false) # stop_=false: clear_viewer's default stops the viewer,
                                       # which would trip the `viewer.stop && break` below at i=1
    bring_viewer_to_front()
    start_time_ns = time_ns()
    for (i, state) in enumerate(log.syslog)
        viewer.stop && break
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == length(log.syslog)
            update_segments!(viewer, state; scale=0.08, kite_scale=2.0)
            update_status_text!(viewer, state; height=state.Z[1])
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            start_time_ns = time_ns()
        end
    end
    replaying[] = false
    stop(viewer)
end

on(viewer.btn_PLAY.clicks) do _
    # The built-in handler already toggled `viewer.stop` above; if a replay is running, clicking
    # RUN again reads as its own built-in "PAUSE" (viewer.stop is now true, the loop above breaks
    # on its next iteration) rather than starting a second, overlapping replay.
    if !replaying[]
        @async replay()
    end
end
on(viewer.btn_STOP.clicks) do _
    stop(viewer)
end

replay()
nothing
