using StaticArrays, BenchmarkTools

const MyFloat = Float64

sys_state_dict = Dict(:time      => 0,
    :t_sim     => 0,
    :sys_state => 0,
    :e_mech    => 0,
    :orient    => [0.530989, 0.466959, -0.466959, -0.530989],
    :elevation => 1.2426,
    :azimuth   => 0,
    :l_tether  => 150,
    :v_reelout => 0,
    :winch_force => 559.847,
    :depower   => 0.25,
    :steering  => 0,
    :heading   => 0,
    :course    => 0,
    :v_app     => 12.5799,
    :vel_kite  => [0, 0, 0],
    :X         => Union{Float64, Int64}[0, 8.90221, 17.5546, 25.9174, 33.9673, 41.687, 49.0618, 49.2317, 50.7465, 50.4513, 50.4513],
    :Y         => Union{Float64, Int64}[0, 0, 0, 0, 0, 0, 0, 0, 0, 2.84247, -2.84247],
    :Z         => Union{Float64, Int64}[0, 23.41, 46.9136, 70.5217, 94.2383, 118.064, 142.0, 147.029, 149.031, 146.739, 146.739]
)

P = 11
Base.@kwdef mutable struct SysState{P}
    "time since start of simulation in seconds"
    time::Float64
    "time needed for one simulation timestep"
    t_sim::Float64
    "state of system state control"
    sys_state::Int16
    "mechanical energy [Wh]"
    e_mech::Float64
    "orientation of the kite (quaternion, order w,x,y,z)"
    orient::MVector{4, Float32}
    "elevation angle in radians"
    elevation::MyFloat
    "azimuth angle in radians"
    azimuth::MyFloat
    "tether length [m]"
    l_tether::MyFloat
    "reel out velocity [m/s]"
    v_reelout::MyFloat
    "tether force [N]"
    force::MyFloat
    "depower settings [0..1]"
    depower::MyFloat
    "steering settings [-1..1]"
    steering::MyFloat
    "heading angle in radian"
    heading::MyFloat
    "course angle in radian"
    course::MyFloat
    "norm of apparent wind speed [m/s]"
    v_app::MyFloat
    "velocity vector of the kite"
    vel_kite::MVector{3, MyFloat}
    "vector of particle positions in x"
    X::MVector{P, MyFloat}
    "vector of particle positions in y"
    Y::MVector{P, MyFloat}
    "vector of particle positions in z"
    Z::MVector{P, MyFloat}
end 

sys_state_dict2struct(dict) = SysState{P}(; pairs(dict)...)

sys_state_dict2struct(sys_state_dict)
