module KiteViewers

using PrecompileTools: @setup_workload, @compile_workload 
using GeometryBasics, Rotations, GLMakie, FileIO, LinearAlgebra, Printf, Parameters, Reexport
import GeometryBasics:Point3f, GeometryBasics.Point2f
using KiteUtils

export Viewer3D, AbstractKiteViewer, AKV                        # types
export clear_viewer, update_system, save_png, stop, set_status  # functions
@reexport using GLMakie: on

const KITE_SPRINGS = 8 

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

@setup_workload begin
	# Putting some things in `@setup_workload` instead of `@compile_workload` can reduce the size of the
	# precompile file and potentially make loading faster.
	# list = [OtherType("hello"), OtherType("world!")]
	set_data_path()
	@compile_workload begin
		# all calls in this block will be precompiled, regardless of whether
		# they belong to your package or not (on Julia 1.8 and higher)
		viewer=Viewer3D()
        close(viewer.screen)
        nothing
	end
end

end
