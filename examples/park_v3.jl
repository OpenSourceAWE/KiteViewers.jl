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
init(viewer, segments)

function replay()
    clear_viewer(viewer; stop_=false) # stop_=false: clear_viewer's default stops the viewer,
                                       # which would trip the `viewer.stop && break` below at i=1
    bring_viewer_to_front()
    start_time_ns = time_ns()
    for (i, state) in enumerate(log.syslog)
        viewer.stop && break
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == length(log.syslog)
            update_segments!(viewer, state; scale=0.08)
            update_status_text!(viewer, state; height=state.Z[1])
            wait_until(start_time_ns + dt*1e9, always_sleep=true)
            start_time_ns = time_ns()
        end
    end
end

on(viewer.btn_PLAY.clicks) do _
    if viewer.stop
        @async begin
            replay()
            stop(viewer)
        end
    end
end
on(viewer.btn_STOP.clicks) do _
    stop(viewer)
end

replay()
stop(viewer)
nothing
