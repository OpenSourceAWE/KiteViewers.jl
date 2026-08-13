function create_coordinate_system(scene, points = 10, max_x = 15.0)
    # create origin
    mesh!(scene, Sphere(Point3f(0, 0, 0), 0.1 * SCALE), color=RGBf(0.7, 0.7, 0.7))
    
    # create x-axis in red
    points += 2
    for x in range(1, length=points)
        mesh!(scene, Sphere(Point3f(x * max_x/points, 0, 0), 0.1 * SCALE), color=:red)
    end
    mesh!(scene, Cylinder(Point3f(-max_x/points, 0, 0), Point3f(points * max_x/points, 0, 0), Float32(0.05 * SCALE)), color=:red)
    for i in range(0, length=points)
        start = Point3f((points + 0.07 * (i-0.5)) * max_x/points, 0, 0)
        stop = Point3f((points + 0.07 * (i+0.5)) * max_x/points, 0, 0)
        mesh!(scene, Cylinder(start, stop, Float32(0.018 * (10 - i) * SCALE)), color=:red)
    end
    
    # create y-axis in green
    points -= 3
    for y in range(0, length = 2points + 1)
        if y - points != 0
            mesh!(scene, Sphere(Point3f(0, (y - points) * SCALE, 0), 0.1 * SCALE), color=:green)
        end
    end
    mesh!(scene, Cylinder(Point3f(0, -(points+1) * SCALE, 0), Point3f(0, (points+1) * SCALE , 0), Float32(0.05 * SCALE)), color=:green)
    for i in range(0, length=10)
        start = Point3f(0, (points+1 + 0.07 * (i-0.5)) * SCALE, 0)
        stop = Point3f(0, (points+1 + 0.07 * (i+0.5)) * SCALE, 0)
        mesh!(scene, Cylinder(start, stop, Float32(0.018 * (10 - i) * SCALE)), color=:green)
    end

    # create z-axis in blue
    points += 1
    for z in range(2, length=points)
        mesh!(scene, Sphere(Point3f(0, 0, (z - 1) * SCALE), 0.1 * SCALE), color=:mediumblue)
    end
    mesh!(scene, Cylinder(Point3f(0, 0, -SCALE), Point3f(0, 0, (points+1) * SCALE), Float32(0.05 * SCALE)), color=:mediumblue)
    for i in range(0, length=10)
        start = Point3f(0, 0, (points+1 + 0.07 * (i-0.5)) * SCALE)
        stop = Point3f(0, 0, (points+1 + 0.07 * (i+0.5)) * SCALE)
        mesh!(scene, Cylinder(start, stop, Float32(0.018 * (10 - i) * SCALE)), color=:dodgerblue3)
    end 
end

"""
    SegmentType

The three kinds of segment a topology matrix passed to [`init`](@ref) can contain, rendered
respectively as a thick yellow cylinder (`TETHER`), a thin yellow cylinder (`BRIDLE`), and a
thin black cylinder (`WING`).
"""
@enum SegmentType TETHER=1 BRIDLE=2 WING=3

const TETHER_RADIUS = 0.5f0 # relative to the built-in tether cylinder marker, see `init_system`
const BRIDLE_RADIUS = 0.3f0
const WING_RADIUS = 0.3f0
const POINT_RADIUS = 0.015f0 # absolute, in scene units; the built-in sphere marker (0.07*SCALE)
                              # is sized for the sparse legacy topologies and overlaps into a
                              # solid blob on a dense point set like the V3 kite's 44 points
const TETHER_POINT_RADIUS = Float32(0.045 * SCALE) # the legacy `init_system` particle size, 4x the
                              # thinned tether cylinder: a 2x bead is 2 px at replay zoom, invisible

"""
    load_segments(filename) -> Matrix{Int64}

Read a segment topology CSV like `data/v3_segments.csv` (columns `segment,point1,point2,
segment_type`; the first column is ignored, it is just the row number) into the `n × 3` integer
matrix expected by [`init`](@ref): `(point1, point2, segment_type)`, with `segment_type` mapped
from the strings `"tether"`/`"bridle"`/`"wing"` onto the [`SegmentType`](@ref) values.
"""
function load_segments(filename)
    lines = readlines(filename)
    type_of = Dict("tether" => Int(TETHER), "bridle" => Int(BRIDLE), "wing" => Int(WING))
    n = length(lines) - 1
    segments = Matrix{Int64}(undef, n, 3)
    for (i, line) in enumerate(@view lines[2:end])
        fields = split(line, ',')
        segments[i, 1] = parse(Int64, fields[2])
        segments[i, 2] = parse(Int64, fields[3])
        segments[i, 3] = type_of[fields[4]]
    end
    segments
end

"""
    init_segments(kv::AKV, segments::AbstractMatrix{<:Integer})

Set up `kv` to render an arbitrary point/segment topology instead of the built-in one-point/
four-point/three-line kite models — used to replay a V3 kite log. `segments` is an `n × 3`
integer matrix of `(point1, point2, segment_type)`, one row per segment, with `segment_type` one
of the [`SegmentType`](@ref) values; load it from a CSV with [`load_segments`](@ref).

Tether and bridle segments reuse the viewer's built-in yellow tether layer (`kv.positions`/
`kv.markersizes`/`kv.rotation`, resized), with tether segments rendered thicker than bridle
segments; wing segments get a new black layer. The built-in point-sphere layer (`kv.part_positions`)
is hidden and replaced by a new layer with a much smaller marker, sized for a dense point cloud —
except on the points of the main tether, which keep a bead twice their cylinder's radius so its
segmentation stays readable. Call [`update_segments!`](@ref) every frame afterwards to move the
points.
"""
function init_segments(kv::AKV, segments::AbstractMatrix{<:Integer})
    n_points = maximum(@view segments[:, 1:2])
    is_wing = segments[:, 3] .== Int(WING)
    n_tb = count(!, is_wing)
    n_wing = count(is_wing)

    kv.seg_topology = Matrix{Int64}(segments)
    kv.points = Vector{Point3f}(undef, n_points)
    kv.part_positions[] = Point3f[] # hide the built-in (oversized) point-sphere layer

    tb_radius = [t == Int(TETHER) ? TETHER_RADIUS : BRIDLE_RADIUS for t in segments[.!is_wing, 3]]
    kv.positions[]   = [Point3f(0, 0, 0) for _ in 1:n_tb]
    kv.markersizes[] = [Point3f(tb_radius[i], tb_radius[i], 1) for i in 1:n_tb]
    kv.rotation[]    = [Point3f(1, 0, 0) for _ in 1:n_tb]

    wing_pos = Observable([Point3f(0, 0, 0) for _ in 1:n_wing])
    wing_mrk = Observable([Point3f(WING_RADIUS, WING_RADIUS, 1) for _ in 1:n_wing])
    wing_rot = Observable([Point3f(1, 0, 0) for _ in 1:n_wing])
    cyl = Cylinder(Point3f(0, 0, -0.5), Point3f(0, 0, 0.5), Float32(0.035 * SCALE))
    meshscatter!(kv.scene3D, wing_pos, marker=cyl, rotation=wing_rot, markersize=wing_mrk, color=:black)
    kv.wing_positions   = wing_pos
    kv.wing_markersizes = wing_mrk
    kv.wing_rotation    = wing_rot

    point_pos = Observable([Point3f(0, 0, 0) for _ in 1:n_points])
    sphere = Sphere(Point3f(0, 0, 0), POINT_RADIUS)
    point_size = ones(Float32, n_points)
    point_size[unique(segments[segments[:, 3] .== Int(TETHER), 1:2])] .= TETHER_POINT_RADIUS / POINT_RADIUS
    meshscatter!(kv.scene3D, point_pos, marker=sphere, markersize=point_size, color=:yellow)
    kv.point_positions = point_pos
    kv
end

"""
    segment_geometry(points, rows, radius_of)

Cylinder midpoint, `(radius, radius, length)` markersize, and unit-vector rotation for each
segment in `rows` (a `n × 3` slice of `(point1, point2, segment_type)`), reading endpoints from
`points`. `radius_of(segment_type)` returns the relative radius for a segment type. Shared by the
two segment layers [`update_segments!`](@ref) writes to.
"""
function segment_geometry(points, rows, radius_of)
    n = size(rows, 1)
    pos = Vector{Point3f}(undef, n)
    mrk = Vector{Point3f}(undef, n)
    rot = Vector{Point3f}(undef, n)
    for i in 1:n
        a, b = points[rows[i, 1]], points[rows[i, 2]]
        pos[i] = (a + b) / 2
        len = norm(b - a)
        r = radius_of(rows[i, 3])
        mrk[i] = Point3f(r, r, len)
        rot[i] = len > 0 ? normalize(b - a) : Point3f(1, 0, 0)
    end
    pos, mrk, rot
end

"""
    update_segments!(kv::AKV, state::SysState; scale=1.0, kite_scale=1.0)

Update a viewer set up with [`init`](@ref) to the point positions in `state`: moves the point
spheres and recomputes every segment's cylinder midpoint, length and orientation from the
topology passed to `init`. Only positions `1:n_points` of `state.X/Y/Z` are used — extra slots
(VSM panel corners, wing/body origins) are ignored.

Unlike [`update_system`](@ref), this does not touch the kite mesh, quaternion, or status text;
call [`update_status_text!`](@ref) separately if needed.

# Keyword Arguments
- `scale=1.0`: scaling factor applied to all point positions.
- `kite_scale=1.0`: extra scaling of bridle and wing, so a small kite stays visible next to a long
  tether. The centre is the end of the main tether — its only point shared with a bridle or wing
  segment, the KCU — which keeps the tether itself untouched and grows the bridle with the wing,
  the same convention as [`update_system`](@ref). A topology whose tether ends nowhere falls back
  to the centroid of the scaled points.
"""
function update_segments!(kv::AKV, state::SysState; scale=1.0, kite_scale=1.0)
    segments = kv.seg_topology
    n_points = length(kv.points)
    for i in 1:n_points
        kv.points[i] = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
    end

    is_wing = segments[:, 3] .== Int(WING)
    is_tether = segments[:, 3] .== Int(TETHER)
    tether_points = unique(segments[is_tether, 1:2])
    scaled = setdiff(1:n_points, tether_points)
    if kite_scale != 1 && !isempty(scaled)
        attachment = intersect(tether_points, unique(segments[.!is_tether, 1:2]))
        center = isempty(attachment) ? sum(kv.points[i] for i in scaled) / length(scaled) :
                                       kv.points[first(attachment)]
        for i in scaled
            kv.points[i] = center + kite_scale * (kv.points[i] - center)
        end
    end
    kv.point_positions[] = copy(kv.points)

    radius_tb(t) = t == Int(TETHER) ? TETHER_RADIUS : BRIDLE_RADIUS
    radius_wing(_) = WING_RADIUS

    kv.positions[], kv.markersizes[], kv.rotation[] =
        segment_geometry(kv.points, @view(segments[.!is_wing, :]), radius_tb)
    kv.wing_positions[], kv.wing_markersizes[], kv.wing_rotation[] =
        segment_geometry(kv.points, @view(segments[is_wing, :]), radius_wing)
    nothing
end

# draw the kite power system, consisting of the tether, the kite and the state (text and numbers)
function init_system(kv::AbstractKiteViewer, scene; show_kite=true)
    sphere = Sphere(Point3f(0, 0, 0), Float32(0.07 * SCALE))
    meshscatter!(scene, kv.part_positions, marker=sphere, markersize=1.0, color=:yellow)
    cyl = Cylinder(Point3f(0,0,-0.5), Point3f(0,0,0.5), Float32(0.035 * SCALE))        
    meshscatter!(scene, kv.positions, marker=cyl, rotation=kv.rotation, markersize=kv.markersizes, color=:yellow)
    if show_kite
        meshscatter!(scene, kite_pos, marker=KITE, markersize = 0.25, rotation=quat, color=:blue)
    end
    font = default_viewer_font(kv.set)
    text!(scene, textnode, position  = Point2f(50, 110), fontsize=TEXT_SIZE, font=font, align = (:left, :top), space=:pixel)
    line_spacing = TEXT_SIZE + 4
    half_line_shift = 0.5 * line_spacing
    upper_right_lines = [@lift(begin
        lines = split($textnode2, '\n')
        i <= length(lines) ? lines[i] : ""
    end) for i in 1:5]
    [text!(scene, upper_right_lines[i], position=Point2f(POS_X, POS_Y + half_line_shift - (i-1) * line_spacing),
           fontsize=TEXT_SIZE, font=font, align=(:left, :top), space=:pixel) for i in 1:5]
end

"""
    update_system(kv::AKV, state::SysState; scale=1.0, kite_scale=1.0, ned=true, 
                  wind=[:v_wind_200m, :v_wind_kite])

Update the 3D visualization of the kite power system, including the tether, kite, and status text.

Moves all tether segment particles and the kite to their new positions based on the given system state,
recalculates cylinder positions, sizes, and rotations for the tether rendering, updates the kite orientation,
and refreshes the on-screen status text (time, height, elevation, azimuth, forces, power, energy, wind, etc.).

Supports one-point, four-point, and three-line (four-point 3L) kite models.

# Arguments
- `kv::AKV`:       the kite viewer instance.
- `state::SysState`: the current system state containing positions, orientation, and flight data.

# Keyword Arguments
- `scale=1.0`:       scaling factor applied to all particle positions.
- `kite_scale=1.0`:  additional scaling factor for the kite relative to the pod/bridle attachment point.
- `ned=true`:        if `true`, convert the orientation quaternion from NED to viewer convention.
- `wind=[:v_wind_200m, :v_wind_kite]`: list of wind fields to display in the status text.
  Supported symbols: `:v_wind_gnd`, `:v_wind_200m`, `:v_wind_kite`.
"""
function update_system(kv::AKV, state::SysState; scale=1.0, kite_scale=1.0, ned=true,
                       wind=[:v_wind_200m, :v_wind_kite])
    threepoint = length(state.Z) == kv.set.segments+1 # check if this is true
    fourpoint = length(state.Z) == kv.set.segments+5
    fourpoint_3l = length(state.Z) == kv.set.segments*3+6
    if fourpoint
        height = state.Z[end-2]
    else
        height = state.Z[end]
    end
    
    # move the particles to the correct position
    if threepoint || fourpoint
        for i in range(1, length=kv.set.segments+1)
            kv.points[i] = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
        end
        if fourpoint
            pos_pod = Point3f(state.X[kv.set.segments+1], state.Y[kv.set.segments+1], state.Z[kv.set.segments+1]) * scale
            # enlarge 4 point kite
            for i in kv.set.segments+2:length(state.Z)
                pos_abs = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
                pos_rel = pos_abs-pos_pod
                kv.points[i] = pos_abs + (kite_scale-1.0) * pos_rel
            end
        end
    elseif fourpoint_3l
        for i in 3:3:length(state.Z) # middle points
            kv.points[i] = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
        end
        y_kite = normalize(Point3f(state.X[end-2], state.Y[end-2], state.Z[end-2]) - Point3f(state.X[end-1], state.Y[end-1], state.Z[end-1]))
        for i in 1:3:length(state.Z) # left and right points, get bigger distance to each other
            left = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
            right = Point3f(state.X[i+1], state.Y[i+1], state.Z[i+1]) * scale
            distance = norm(left - right)
            y_local = distance * y_kite
            kv.points[i] = left + (kite_scale-1.0) * y_local
            kv.points[i+1] = right - (kite_scale-1.0) * y_local
        end
        # # enlarge 3line kite
        # last_middle_line_pos = Point3f(state.X[kv.set.segments+3], state.Y[kv.set.segments+3], state.Z[kv.set.segments+3]) * scale
        # for i in kv.set.segments*3+4:length(state.Z)
        #     pos_abs = Point3f(state.X[i], state.Y[i], state.Z[i]) * scale
        #     pos_rel = pos_abs-last_middle_line_pos
        #     kv.points[i] = pos_abs + (kite_scale-1.0) * pos_rel
        # end
    end
    kv.part_positions[] = [(kv.points[k]) for k in 1:length(state.Z)]

    # calc cylinder positions
    function calc_positions(s)
        if fourpoint_3l
            tmp = [(kv.points[k] + kv.points[k+3])/2 for k in 1:s*3]
            push!(tmp, (kv.points[s*3+3]+kv.points[s*3+4]) / 2)
            push!(tmp, (kv.points[s*3+3]+kv.points[s*3+5]) / 2)
            push!(tmp, (kv.points[s*3+3]+kv.points[s*3+6]) / 2)
            push!(tmp, (kv.points[s*3+4]+kv.points[s*3+5]) / 2)
            push!(tmp, (kv.points[s*3+4]+kv.points[s*3+6]) / 2)
            push!(tmp, (kv.points[s*3+5]+kv.points[s*3+6]) / 2)
        else
            tmp = [(kv.points[k] + kv.points[k+1])/2 for k in 1:s]
            if fourpoint
                push!(tmp, (kv.points[s+1]+kv.points[s+4]) / 2) # S6
                push!(tmp, (kv.points[s+2]+kv.points[s+5]) / 2) # S8
                push!(tmp, (kv.points[s+3]+kv.points[s+5]) / 2) # S7
                push!(tmp, (kv.points[s+2]+kv.points[s+4]) / 2) # S2
                push!(tmp, (kv.points[s+1]+kv.points[s+5]) / 2) # S5
                push!(tmp, (kv.points[s+4]+kv.points[s+3]) / 2) # S4
                push!(tmp, (kv.points[s+1]+kv.points[s+2]) / 2) # S1
                push!(tmp, (kv.points[s+3]+kv.points[s+2]) / 2) # S9
            end
        end
        return tmp
    end
    function calc_markersizes(s)
        if fourpoint_3l
            tmp = [Point3f(1, 1, norm(kv.points[k+3] - kv.points[k])) for k in 1:s*3]
            push!(tmp, Point3f(1, 1, norm(kv.points[s*3+3] - kv.points[s*3+4])))
            push!(tmp, Point3f(1, 1, norm(kv.points[s*3+3] - kv.points[s*3+5])))
            push!(tmp, Point3f(1, 1, norm(kv.points[s*3+3] - kv.points[s*3+6])))
            push!(tmp, Point3f(1, 1, norm(kv.points[s*3+4] - kv.points[s*3+5])))
            push!(tmp, Point3f(1, 1, norm(kv.points[s*3+4] - kv.points[s*3+6])))
            push!(tmp, Point3f(1, 1, norm(kv.points[s*3+5] - kv.points[s*3+6])))
        else
            tmp = [Point3f(1, 1, norm(kv.points[k+1] - kv.points[k])) for k in 1:s]
            if fourpoint
                push!(tmp, Point3f(1, 1, norm(kv.points[s+1] - kv.points[s+4]))) # S6
                push!(tmp, Point3f(1, 1, norm(kv.points[s+2] - kv.points[s+5]))) # S8
                push!(tmp, Point3f(1, 1, norm(kv.points[s+3] - kv.points[s+5]))) # S7
                push!(tmp, Point3f(1, 1, norm(kv.points[s+2] - kv.points[s+4]))) # S2
                push!(tmp, Point3f(1, 1, norm(kv.points[s+1] - kv.points[s+5]))) # S5
                push!(tmp, Point3f(1, 1, norm(kv.points[s+4] - kv.points[s+3]))) # S4
                push!(tmp, Point3f(1, 1, norm(kv.points[s+1] - kv.points[s+2]))) # S1
                push!(tmp, Point3f(1, 1, norm(kv.points[s+3] - kv.points[s+2]))) # S9
            end
        end
        return tmp
    end
    function calc_rotations(s)
        if fourpoint_3l
            tmp = [normalize(kv.points[k+3] - kv.points[k]) for k in 1:s*3]
            push!(tmp, normalize(kv.points[s*3+3] - kv.points[s*3+4]))
            push!(tmp, normalize(kv.points[s*3+3] - kv.points[s*3+5]))
            push!(tmp, normalize(kv.points[s*3+3] - kv.points[s*3+6]))
            push!(tmp, normalize(kv.points[s*3+4] - kv.points[s*3+5]))
            push!(tmp, normalize(kv.points[s*3+4] - kv.points[s*3+6]))
            push!(tmp, normalize(kv.points[s*3+5] - kv.points[s*3+6]))
        else
            tmp = [normalize(kv.points[k+1] - kv.points[k]) for k in 1:s]
            if fourpoint
                push!(tmp, normalize(kv.points[s+1] - kv.points[s+4]))
                push!(tmp, normalize(kv.points[s+2] - kv.points[s+5]))
                push!(tmp, normalize(kv.points[s+3] - kv.points[s+5]))
                push!(tmp, normalize(kv.points[s+2] - kv.points[s+4]))
                push!(tmp, normalize(kv.points[s+1] - kv.points[s+5]))
                push!(tmp, normalize(kv.points[s+4] - kv.points[s+3]))
                push!(tmp, normalize(kv.points[s+1] - kv.points[s+2]))
                push!(tmp, normalize(kv.points[s+3] - kv.points[s+2]))
            end
        end
        return tmp
    end

    # move, scale and turn the cylinder correctly
    kv.positions[]   = calc_positions(kv.set.segments)
    kv.markersizes[] = calc_markersizes(kv.set.segments)
    kv.rotation[]   = calc_rotations(kv.set.segments)

    if ned
        q0 = quat2viewer(state.orient)                        # SVector in the order w,x,y,z
    else
        q0 = state.orient                                     # SVector in the order w,x,y,z
    end
    quat[]     = Quaternionf(q0[2], q0[3], q0[4], q0[1])  # the constructor expects the order x,y,z,w
    if fourpoint
        s = kv.set.segments
        kite_pos[] = 0.8 * 0.5 * (kv.points[s+4] + kv.points[s+5]) + 0.2 * kv.points[s+1]
    elseif fourpoint_3l
        s = kv.set.segments
        kite_pos[] = 0.8 * 0.5 * (kv.points[s*3+4] + kv.points[s*3+5]) + 0.2 * kv.points[s*3+3]
    else
        # move and turn the kite to the new position
        kite_pos[] = Point3f(state.X[kv.set.segments+1], state.Y[kv.set.segments+1], state.Z[kv.set.segments+1]) * scale
    end

    update_status_text!(kv, state; height, wind)
end

"""
    update_status_text!(kv::AKV, state::SysState; height=state.Z[end], wind=[:v_wind_200m, :v_wind_kite])

Refresh the on-screen status text (time, height, elevation, azimuth, forces, power, energy, wind)
from `state`. Shared by [`update_system`](@ref), which passes the topology-specific `height` it
already computed, and [`update_segments!`](@ref)-based replay, which has no such convention and
should pass whichever `state.Z` slot best represents the kite's height.

# Keyword Arguments
- `height=state.Z[end]`: height value to display [m].
- `wind=[:v_wind_200m, :v_wind_kite]`: list of wind fields to display in the status text.
  Supported symbols: `:v_wind_gnd`, `:v_wind_200m`, `:v_wind_kite`.
"""
function update_status_text!(kv::AKV, state::SysState; height=state.Z[end],
                             wind=[:v_wind_200m, :v_wind_kite])
    azimuth = state.azimuth
    if azimuth ≈ 0 # suppress -0 and replace it with 0
        azimuth = zero(azimuth)
    end
    # calculate power and energy
    power = state.winch_force[1] * state.v_reelout[1]
    if abs(power) < 0.001
        power = 0
    end
    kv.energy = state.e_mech
    kv.step+=1

    # print state values
    if mod(kv.step, kv.mod_text) == 1
        msg = "time:      $(@sprintf("%7.2f", state.time)) s\n" *
            "height:    $(@sprintf("%7.2f", height)) m     "  * "length:  $(@sprintf("%7.2f", state.l_tether[1])) m\n" *
            "elevation: $(@sprintf("%7.2f", state.elevation/pi*180.0)) °     " * "heading: $(@sprintf("%7.2f", state.heading/pi*180.0)) °\n" *
            "azimuth:   $(@sprintf("%7.2f", azimuth/pi*180.0)) °     " * "course:  $(@sprintf("%7.2f", state.course/pi*180.0)) °\n" *
            "v_reelout: $(@sprintf("%7.2f", state.v_reelout[1])) m/s   " * "p_mech: $(@sprintf("%8.2f", power)) W\n" *
            "force:     $(@sprintf("%7.2f", state.winch_force[1]    )) N     " * "energy: $(@sprintf("%8.2f", kv.energy)) Wh\n"
        textnode[] = msg
        wind_msg = ""
        if :v_wind_gnd in wind
            wind_msg = "\nwind_gnd:  $(@sprintf("%4.1f", norm(state.v_wind_gnd))) m/s"
        end
        if :v_wind_200m in wind
            wind_msg = wind_msg * "\nwind@200m: $(@sprintf("%4.1f", norm(state.v_wind_200m))) m/s"
        end
        if :v_wind_kite in wind
            wind_msg = wind_msg * "\nwind@kite: $(@sprintf("%4.1f", norm(state.v_wind_kite))) m/s"
        end
        textnode2[] = "depower:  $(@sprintf("%6.2f", state.depower*100)) %\n" *
                      "steering: $(@sprintf("%6.2f", state.steering*100)) %" * wind_msg
    end
    nothing
end

function reset_view(cam, scene3D)
    update_cam!(scene3D.scene, Vec3f(-15.425113, -18.925116, 5.5), Vec3f(-1.5, -5.0, 5.5))
end

function zoom_scene(camera, scene, zoom=1.0f0)
    @extractvalue camera (fov, near, lookat, eyeposition, upvector)
    dir_vector = eyeposition - lookat
    new_eyeposition = lookat + dir_vector * (2.0f0 - zoom)
    update_cam!(scene, new_eyeposition, lookat)
end

function reset_and_zoom(camera, scene3D, zoom)
    reset_view(camera, scene3D)
    if ! (zoom ≈ 1.0) 
        zoom_scene(camera, scene3D.scene, zoom)  
    end
end