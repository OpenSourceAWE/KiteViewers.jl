#= MIT License

Copyright (c) 2020, 2021, 2024 Uwe Fechner, Bart van de Lint

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

if Sys.iswindows()
    TEXT_SIZE::Int64 = 14
else
    TEXT_SIZE::Int64 = 16
end
@consts begin
    SCALE = 1.2 
    INITIAL_HEIGHT =  80.0*se().zoom # meter, for demo
    MAX_HEIGHT     = 200.0*se().zoom # meter, for demo
    KITE = FileIO.load(joinpath(dirname(get_data_path()), se().model))
    FLYING     = [false]
    PLAYING    = [false]
    GUI_ACTIVE = [false]
    AXIS_LABEL_SIZE = 30
    running   = Observable(false)
    starting  = [0]
    zoom      = [1.0]
    steering  = [0.0]
    textnode  = Observable("")  # lower left
    textnode2  = Observable("") # upper right
    fontsize  = Observable(TEXT_SIZE)
    fontsize2 = Observable(AXIS_LABEL_SIZE)
    status = Observable("")
    plot_file = Observable("")
    p1 = Observable(Vector{Point2f}(undef, 6000)) # 5 min
    p2 = Observable(Vector{Point2f}(undef, 6000)) # 5 min
    pos_x = Observable(0.0f0)
    quat            = Observable(Quaternionf(0,0,0,1))                                     # orientation of the kite
    kite_pos        = Observable(Point3f(1,0,0))                                           # position of the kite
end 

last_status::String=""

"""
    abstract type AbstractKiteViewer

All kite viewers must inherit from this type. All methods that are defined on this type must work
with all kite viewers. All exported methods must work on this type. 
"""
abstract type AbstractKiteViewer end

"""
    const AKV = AbstractKiteViewer

Short alias for the AbstractKiteViewer. 
"""
const AKV = AbstractKiteViewer

"""
    Viewer3D <: AbstractKiteViewer

Mutable struct representing a 3D kite power system viewer, built on GLMakie.

Holds the Makie figure, 3D scene, camera, screen, particle/tether geometry observables,
settings, UI buttons, optional menus, and simulation bookkeeping (step counter, energy,
stop flag, etc.).

Use the outer constructors [`Viewer3D(show_kite, autolabel; precompile)`](@ref) or
[`Viewer3D(set, show_kite, autolabel; precompile, menus)`](@ref) to create an instance.
"""
mutable struct Viewer3D <: AKV
    fig::Figure
    scene3D::LScene
    cam::Camera3D
    screen::GLMakie.Screen
    points::Vector{Point{3, Float32}}
    positions::Observable{Vector{GeometryBasics.Point{3, Float32}}}
    part_positions::Observable{Vector{GeometryBasics.Point{3, Float32}}}
    markersizes::Observable{Vector{GeometryBasics.Point{3, Float32}}}
    rotation::Observable{Vector{GeometryBasics.Point{3, Float32}}}
    set::Settings
    btn_RESET::Button
    btn_ZOOM_in::Button
    btn_ZOOM_out::Button
    btn_PLAY::Button
    btn_AUTO::Button
    btn_PARKING::Button
    btn_STOP::Button
    menu::Union{Menu, Nothing}
    menu_rel_tol::Union{Menu, Nothing}
    menu_time_lapse::Union{Menu, Nothing}
    menu_project::Union{Menu, Nothing}
    t_sim::Union{Textbox, Nothing}
    btn_OK::Union{Button, Nothing}
    sw::Toggle
    step::Int64
    mod_text::Int64 # 4 means at 40Hz update rate the text is updated only at 10Hz
    energy::Float64
    show_kite::Bool
    stop::Bool
end

"""
    clear_viewer(kv::AKV; stop_=true)

Reset the viewer to its initial state by setting the step counter to 1 and the accumulated
energy to zero. By default, the simulation is also stopped (status set to "Stopped" and
`running` set to `false`). Pass `stop_=false` to reset the counters without stopping.

# Arguments
- `kv::AKV`: the kite viewer instance.

# Keyword Arguments
- `stop_=true`: whether to call `stop(kv)` after resetting.
"""
function clear_viewer(kv::AKV; stop_=true)
    kv.step = 1
    kv.energy = 0
    if stop_
        stop(kv)
    end
end

"""
    stop(kv::AKV)

Stop the simulation. Sets the viewer's stop flag to `true`, updates the status text
to "Stopped", and sets `running` to `false`.
"""
function stop(kv::AKV)
    kv.stop = true
    status[]="Stopped"
    running[]=false
end

"""
    pause(kv::AKV)

Pause the simulation. Sets the viewer's stop flag to `true`, saves the current status
text in `last_status`, and updates the status to "Paused".
"""
function pause(kv::AKV)
    global last_status
    kv.stop = true
    last_status=status[]
    status[]="Paused"
end

"""
    set_status(kv::AKV, status_text)

Set the viewer status text to `status_text`. If the new status is not `"Paused"`,
the current status is saved in `last_status` before updating.
"""
function set_status(kv::AKV, status_text)
    global last_status
    if status_text != "Paused"
        last_status = status[]
    end
    status[] = status_text
end

"""
    Viewer3D(show_kite=true, autolabel="Autopilot"; precompile=false)

Convenience constructor that loads settings via `se()` and forwards to the full constructor.

# Arguments
- `show_kite=true`:        whether to render the kite mesh.
- `autolabel="Autopilot"`: label for the autopilot toggle button.

# Keyword Arguments
- `precompile=false`: if `true`, the viewer is created in precompilation mode
  (window hidden, reduced resolution).
"""
function Viewer3D(show_kite=true, autolabel="Autopilot"; precompile=false)
    set = se()
    Viewer3D(set, show_kite, autolabel; precompile) 
end

"""
    Viewer3D(set::Settings, show_kite=true, autolabel="Autopilot"; precompile=false, menus=false)

Create and display a 3D viewer window for the kite power system.

Sets up the GLMakie figure, 3D scene with tether cylinders and kite mesh, camera,
UI buttons (RESET, ZOOM, PLAY, STOP, AUTO, PARKING), status text overlays, and
optionally dropdown menus for plot selection, tolerances, time lapse, and project management.

# Arguments
- `set::Settings`:         simulation/viewer settings.
- `show_kite=true`:        whether to render the kite mesh.
- `autolabel="Autopilot"`: label for the autopilot toggle button.

# Keyword Arguments
- `precompile=false`: if `true`, the viewer is created in precompilation mode.
- `menus=false`:      if `true`, show additional dropdown menus for plot type, tolerances,
  time lapse, and project management.
"""
function Viewer3D(set::Settings, show_kite=true, autolabel="Autopilot"; precompile=false, menus=false) 
    global last_status
    WIDTH  = 840
    HEIGHT = 900
    fig = Figure(size=(WIDTH, HEIGHT), backgroundcolor=RGBf(0.7, 0.8, 1))
    sub_fig = fig[1,1]
    if menus
        menu1 = Menu(fig, bbox = fig.scene.viewport, 
                    options = ["plot_main", "plot_control", "plot_elev_az", "plot_timing", "load simulation", "save simulation"], default = "plot_main")
        menu1.width[] =120
        menu1.halign[]=:left
        menu1.valign[]=:top
        menu1.alignmode[]=Outside(30)
        menu2 = Menu(fig, bbox = fig.scene.viewport, 
                    options = ["0.001", "0.0001", "0.00001", "0.000001"], default = "0.001")
        menu2.width[] =120
        menu2.halign[]=:left
        menu2.valign[]=:top
        menu2.alignmode[]=Outside(30, 0, 0, 60)
        label2 = Label(fig, "rel_tol", bbox=fig.scene.viewport)
        label2.halign[]=:left
        label2.valign[]=:top
        label2.alignmode=Outside(160, 0, 0, 70)
        
        menu3 = Menu(fig, bbox = fig.scene.viewport, 
                options = ["1x", "2x", "3x", "4x", "6x", "8x"], default = "4x")
        menu3.width[] =120
        menu3.halign[]=:left
        menu3.valign[]=:top
        menu3.alignmode[]=Outside(30, 0, 0, 90)
        label3 = Label(fig, "time_lapse", bbox=fig.scene.viewport)
        label3.halign[]=:left
        label3.valign[]=:top
        label3.alignmode=Outside(160, 0, 0, 100)

        menu4 = Menu(fig, bbox = fig.scene.viewport, 
                options = ["load...", "save as...", "edit..."], default = "load...")
        menu4.width[] =120
        menu4.halign[]=:left
        menu4.valign[]=:top
        menu4.alignmode[]=Outside(30, 0, 0, 120)
        label4 = Label(fig, "project", bbox=fig.scene.viewport)
        label4.halign[]=:left
        label4.valign[]=:top
        label4.alignmode=Outside(160, 0, 0, 130)

        tb = Textbox(fig, bbox = fig.scene.viewport, placeholder = "Simulation time",
                     validator = UInt16, stored_string="460")
        tb.width[] =120
        tb.halign[]=:left
        tb.valign[]=:top
        tb.alignmode[]=Outside(30, 0, 0, 160)
        label3 = Label(fig, "t_sim [s]", bbox=fig.scene.viewport)
        label3.halign[]=:left
        label3.valign[]=:top
        label3.alignmode=Outside(160, 0, 0, 167)
        btn_OK         = Button(fig, bbox=fig.scene.viewport, label = "OK")
        btn_OK.halign[]=:left
        btn_OK.valign[]=:top
        btn_OK.alignmode[]=Outside(160, 0, 0, 30)
    else
        menu1=nothing
        menu2=nothing
        menu3=nothing
        menu4=nothing
        tb = nothing
        btn_OK=nothing
    end

    scene2D = LScene(fig[3,1], show_axis=false, height=16)
    scene3D = LScene(sub_fig, show_axis=false, scenekw=(limits=Rect(-7,-10.0,0, 11,10,11), size=(800, 800)))

    create_coordinate_system(scene3D)
    cam = cameracontrols(scene3D.scene)

    FLYING[1] = false
    PLAYING[1] = false
    GUI_ACTIVE[1] = true

    reset_view(cam, scene3D)

    fontsize[]  = TEXT_SIZE
    fontsize2[] = AXIS_LABEL_SIZE
    text!(scene3D, "z", position = Point3f(0, 0, 14.6), fontsize = fontsize2, align = (:center, :center))
    text!(scene3D, "x", position = Point3f(17, 0,0), fontsize = fontsize2, align = (:center, :center))
    text!(scene3D, "y", position = Point3f( 0, 14.5, 0), fontsize = fontsize2, align = (:center, :center))

    text!(scene2D, status, position = Point2f( 20, 0), fontsize = TEXT_SIZE, align = (:left, :bottom), space=:pixel)
    text!(scene2D, plot_file, position = Point2f( 420, 0), fontsize = TEXT_SIZE, align = (:left, :bottom), space=:pixel)

    textnode2[]="depower:\nsteering:\n"

    fig[2, 1] = buttongrid = GridLayout(tellwidth=false)
    l_sublayout = GridLayout()
    fig[1:3, 1] = l_sublayout
    l_sublayout[:v] = [scene3D, buttongrid, scene2D]

    btn_RESET       = Button(sub_fig, label = "RESET")
    btn_ZOOM_in     = Button(sub_fig, label = "Zoom +")
    btn_ZOOM_out    = Button(sub_fig, label = "Zoom -")
    if precompile
        btn_PLAY_PAUSE  = Button(sub_fig, label = " RUN ")
    else
        btn_PLAY_PAUSE  = Button(sub_fig, label = @lift($running ? "PAUSE" : " RUN "))
    end
    btn_AUTO        = Button(sub_fig, label = autolabel)
    btn_PARKING     = Button(sub_fig, label = "Parking")  
    btn_STOP        = Button(sub_fig, label = "STOP")
    sw = Toggle(sub_fig, active = false)
    label = Label(sub_fig, "repeat")
    
    buttongrid[1, 1:9] = [btn_PLAY_PAUSE, btn_ZOOM_in, btn_ZOOM_out, btn_RESET, btn_AUTO, 
                          btn_PARKING, btn_STOP, sw, label]
    gl_screen = display(fig)

    FLYING[1] = false
    PLAYING[1] = false
    GUI_ACTIVE[1] = true

    reset_view(cam, scene3D)
    points=Vector{Point3f}(undef, set.segments*3+6)
    pos=Observable([Point3f(x,0,0) for x in 1:set.segments+KITE_SPRINGS]) # positions of the tether segments
    part_pos=Observable([Point3f(x,0,0) for x in 1:set.segments+1+4])     # positions of the tether particles
    markersizes     = Observable([Point3f(1,1,1) for x in 1:set.segments+KITE_SPRINGS]) # includes the segment length
    rotation       = Observable([Point3f(1,0,0) for x in 1:set.segments+KITE_SPRINGS]) #unit vectors corresponding with
                                                                                        #the orientation of the segments 
    mod_text = 4
    s = Viewer3D(fig, scene3D, cam, gl_screen, points, pos, part_pos, markersizes, 
                 rotation, set, btn_RESET, btn_ZOOM_in, btn_ZOOM_out, 
                 btn_PLAY_PAUSE, btn_AUTO, btn_PARKING, btn_STOP, menu1, menu2, menu3, menu4, tb, btn_OK,
                 sw, 0, mod_text, 0, show_kite, false)
    txt2 = init_system(s, s.scene3D; show_kite=show_kite)

    camera = cameracontrols(s.scene3D.scene)
    reset_view(camera, s.scene3D)
    set_status(s, "Stopped")

    on(s.btn_RESET.clicks) do c
        reset_view(camera, s.scene3D)
        zoom[1] = 1.0
    end

    on(s.btn_ZOOM_in.clicks) do c    
        zoom[1] *= 1.2
        reset_and_zoom(camera, s.scene3D, zoom[1])
    end

    on(s.btn_ZOOM_out.clicks) do c
        zoom[1] /= 1.2
        reset_and_zoom(camera, s.scene3D, zoom[1])
    end
    on(s.btn_STOP.clicks) do c
        stop(s)
    end
    on(s.btn_PLAY.clicks) do c
        if running[]
            last_status=status[]
            status[]="Paused"
            running[]=false
        else
            set_status(s, last_status)
            running[]=true
        end
        s.stop = ! running[]
    end
    on(fig.scene.events.window_area) do x
        dx = x.widths[1] - WIDTH
        dy = x.widths[2] - HEIGHT
        txt2.position[] = Point2f(POS_X+dx, POS_Y+dy)
    end
    status[] = "Stopped"
    s
end

"""
    save_png(viewer; filename="video", index=1)

Save the current viewer frame as a PNG file in the `video/` directory.

The output file is named `<filename><index>.png`, where `index` is zero-padded to
six digits (e.g. `video000001.png`). The `video/` directory is created if it does not exist.

# Keyword Arguments
- `filename="video"`: prefix for the output file name.
- `index=1`:          frame number, zero-padded to six digits in the file name.
"""
function save_png(viewer; filename="video", index = 1)
    mkpath("video")
    buffer = IOBuffer()
    @printf(buffer, "%06i", index) 
    save(joinpath("video", filename * String(take!(buffer)) * ".png"), viewer.fig; update=false)
end
