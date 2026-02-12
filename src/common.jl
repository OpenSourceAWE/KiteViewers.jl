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

# draw the kite power system, consisting of the tether, the kite and the state (text and numbers)
function init_system(kv::AbstractKiteViewer, scene; show_kite=true)
    sphere = Sphere(Point3f(0, 0, 0), Float32(0.07 * SCALE))
    meshscatter!(scene, kv.part_positions, marker=sphere, markersize=1.0, color=:yellow)
    cyl = Cylinder(Point3f(0,0,-0.5), Point3f(0,0,0.5), Float32(0.035 * SCALE))        
    meshscatter!(scene, kv.positions, marker=cyl, rotation=kv.rotation, markersize=kv.markersizes, color=:yellow)
    if show_kite
        meshscatter!(scene, kite_pos, marker=KITE, markersize = 0.25, rotation=quat, color=:blue)
    end
    if Sys.islinux()
        lin_font="/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMono.ttf"
        if isfile(lin_font)
            font=lin_font
        else
            font="/usr/share/fonts/truetype/freefont/FreeMono.ttf"
        end
    else
        font="Courier New"
    end
    if kv.set.fixed_font != ""
        font=kv.set.fixed_font
    end
    text!(scene, textnode, position  = Point2f(50, 110), fontsize=TEXT_SIZE, font=font, align = (:left, :top), space=:pixel)
    text!(scene, textnode2, position  = Point2f(POS_X, POS_Y), fontsize=TEXT_SIZE, font=font, align = (:left, :top), space=:pixel)
end

# update the kite power system, consisting of the tether, the kite and the state (text and numbers)
function update_system(kv::AKV, state::SysState; scale=1.0, kite_scale=1.0, ned=true, 
                       wind=[:v_wind_200m, :v_wind_kite])
    azimuth = state.azimuth
    if azimuth ≈ 0 # suppress -0 and replace it with 0
        azimuth=zero(azimuth)
    end
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
        for i in 1:3:length(state.Z) # left and right points, get bigger distance to eachother
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

    # calculate power and energy
    power = state.winch_force[1] * state.v_reelout[1]
    dt = 1/kv.set.sample_freq
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