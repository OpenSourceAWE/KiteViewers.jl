module KiteViewers

using PrecompileTools: @compile_workload, @setup_workload 
using FileIO, GLMakie, GeometryBasics, LinearAlgebra, Parameters, Printf, Reexport, Rotations
import GeometryBasics: GeometryBasics.Point2f, Point3f
@reexport using KiteUtils
using Pkg

export Viewer3D, AbstractKiteViewer, AKV                               # types
export clear_viewer, update_system, save_png, stop, pause, set_status  # functions
@reexport using GLMakie: on

const KITE_SPRINGS = 8 
const POS_Y = 787 # position of the text in the upper right corner
const POS_X = 626

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
