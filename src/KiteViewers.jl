module KiteViewers

using GeometryBasics, Rotations, GLMakie, FileIO, LinearAlgebra, Printf, Parameters
using KiteUtils

export Viewer3D                                                  # types
export show_window, close_window, init_system, update_points     # functions

const Node = Observable
const Quaternionf0 = Quaternionf
const RGBf0 = RGBf

KiteUtils.set_data_path("") 

include("pure.jl")

# precompile(show_window, (Viewer3D,))

end
