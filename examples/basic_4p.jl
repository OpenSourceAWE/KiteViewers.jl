using KiteViewers, KiteUtils

viewer::Viewer3D = Viewer3D(true);
segments=6
state=demo_state_4p(segments+1)
update_system(viewer, state, kite_scale=0.25, ned=false)
bring_viewer_to_front()
nothing