using KiteViewers, KiteUtils

FXAA = true

viewer::Viewer3D = Viewer3D(true; fxaa=FXAA);
segments=6
state=demo_state_4p(segments+1)
update_system(viewer, state, kite_scale=0.25)
set_title!(viewer, "FXAA = $FXAA")
bring_viewer_to_front()

FXAA = false
viewer2::Viewer3D = Viewer3D(true; fxaa=FXAA, new_window=true);
segments=6
state=demo_state_4p(segments+1)
update_system(viewer2, state, kite_scale=0.25)
set_title!(viewer2, "FXAA = $FXAA")
bring_viewer_to_front()
nothing