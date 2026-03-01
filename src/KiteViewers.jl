module KiteViewers

using PrecompileTools: @compile_workload, @setup_workload 
using FileIO, GeometryBasics, LinearAlgebra, Parameters, Printf, Reexport, Rotations
import GLMakie
using GLMakie: @extractvalue, @lift, Button, Camera3D, Figure, GridLayout, LScene, Label,
    Menu, Observable, Point2f, Point3f, Quaternionf, RGBf, Rect, Textbox, Toggle, Vec3f,
    cam3d!, cameracontrols, mesh!, meshscatter!, Outside, save, scatter!, text!, update_cam!
    
@reexport using KiteUtils
using Pkg

export AKV, AbstractKiteViewer, Viewer3D                               # types
export clear_viewer, pause, save_png, set_status, stop, update_system  # functions
export reactivate_host_app, bring_viewer_to_front
@reexport using GLMakie: on

const KITE_SPRINGS = 8 
const POS_Y = 787 # position of the text in the upper right corner
const POS_X = 626

function default_viewer_font(set)
    if Sys.islinux()
        lin_font = "/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMono.ttf"
        if isfile(lin_font)
            font = lin_font
        else
            font = "/usr/share/fonts/truetype/freefont/FreeMono.ttf"
        end
    elseif Sys.isapple()
        font = "Menlo Bold"
    else
        font = "Courier New"
    end
    if set.fixed_font != ""
        font = set.fixed_font
    end
    font
end

function __init__()
    if isdir(joinpath(pwd(), "data")) && isfile(joinpath(pwd(), "data", "system.yaml"))
        set_data_path(joinpath(pwd(), "data"))
    end
end

include("viewer3D.jl")
include("common.jl")

@with_kw mutable struct KiteLogger
    states::Vector{SysState{7}} = SysState{7}[]
end

"""
    copy_examples()

Copy all example scripts to the folder "examples"
(it will be created if it doesn't exist).
"""
function copy_examples()
    PATH = "examples"
    if ! isdir(PATH) 
        mkdir(PATH)
    end
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", PATH)
    copy_files("examples", readdir(src_path))
end

function copy_viewer_settings()
    files = ["settings.yaml", "system.yaml", "3l_settings.yaml", "kite.obj"]
    dst_path = abspath(joinpath(pwd(), "data"))
    copy_files("data", files)
    set_data_path(joinpath(pwd(), "data"))
    println("Copied $(length(files)) files to $(dst_path) !")
end

function install_examples(add_packages=true)
    copy_examples()
    copy_settings()
    copy_viewer_settings()
    if add_packages
        Pkg.add("KiteUtils")
        Pkg.add("KiteModels")
        Pkg.add("ControlPlots")
        Pkg.add("LaTeXStrings")
        Pkg.add("StatsBase")
        Pkg.add("Timers")
    end
end

function copy_files(relpath, files)
    if ! isdir(relpath) 
        mkdir(relpath)
    end
    src_path = joinpath(dirname(pathof(@__MODULE__)), "..", relpath)
    for file in files
        cp(joinpath(src_path, file), joinpath(relpath, file), force=true)
        chmod(joinpath(relpath, file), 0o774)
    end
    files
end

function reactivate_host_app()
    Sys.isapple() || return nothing
    term = get(ENV, "TERM_PROGRAM", "")
    cmd = if term == "vscode"
        `osascript -e 'tell application "Visual Studio Code" to activate'`
    elseif term == "Apple_Terminal"
        `osascript -e 'tell application "Terminal" to activate'`
    elseif term == "iTerm.app" || term == "iTerm2"
        `osascript -e 'tell application "iTerm" to activate'`
    else
        nothing
    end
    if cmd !== nothing
        try
            run(pipeline(cmd, stdout=devnull, stderr=devnull))
        catch
        end
    end
    nothing
end

function bring_viewer_to_front()
    if Sys.isapple()
        sleep(0.2)
        try
            script = "tell application \"System Events\" to set frontmost of first process whose unix id is $(getpid()) to true"
            run(pipeline(`osascript -e $script`, stdout=devnull, stderr=devnull))
        catch
        end
    end
    nothing
end

@setup_workload begin
	# Putting some things in `@setup_workload` instead of `@compile_workload` can reduce the size of the
	# precompile file and potentially make loading faster.
	# list = [OtherType("hello"), OtherType("world!")]
	set_data_path()
	@compile_workload begin
		# all calls in this block will be precompiled, regardless of whether
		# they belong to your package or not (on Julia 1.8 and higher)
        segments=se().segments
        state=demo_state_4p(segments+1)
        if haskey(ENV, "DISPLAY")
            viewer=Viewer3D(true; precompile=true)
            update_system(viewer, state, kite_scale=0.25)
            close(viewer.screen)
        end
        nothing
	end
end

end
