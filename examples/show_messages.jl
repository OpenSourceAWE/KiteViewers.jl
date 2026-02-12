# http example
using HTTP, JSON3, StructTypes

url = "http://localhost:8080"

function init()
    response = HTTP.get(url*"/init")
    if response.status == 200
        return JSON3.read(response.body)
    else
        return nothing
    end
end

function get_sys_state_dict()
    response = HTTP.get(url*"/sys_state")
    if response.status == 200
        return JSON3.read(response.body)
    else
        return nothing
    end
end

function sys_state_dict2struct(sys_state_dict)
    P = length(sys_state_dict.Z)
    SysState{P}(sys_state_dict[:time],
        sys_state_dict[:t_sim],
        sys_state_dict[:sys_state],
        sys_state_dict[:e_mech],
        sys_state_dict[:orient],
        sys_state_dict[:elevation],
        sys_state_dict[:azimuth],
        sys_state_dict[:l_tether],
        sys_state_dict[:v_reelout],
        sys_state_dict[:winch_force],
        sys_state_dict[:depower],
        sys_state_dict[:steering],
        sys_state_dict[:heading],
        sys_state_dict[:course],
        sys_state_dict[:v_app],
        sys_state_dict[:vel_kite],
        sys_state_dict[:X],
        sys_state_dict[:Y],
        sys_state_dict[:Z],
        sys_state_dict[:var_01],
        sys_state_dict[:var_02],
        sys_state_dict[:var_03],
        sys_state_dict[:var_04],
        sys_state_dict[:var_05],
        sys_state_dict[:var_06],
        sys_state_dict[:var_07],
        sys_state_dict[:var_08],
        sys_state_dict[:var_09],
        sys_state_dict[:var_10],
        sys_state_dict[:var_11],
        sys_state_dict[:var_12],
        sys_state_dict[:var_13],
        sys_state_dict[:var_14],
        sys_state_dict[:var_15],
        sys_state_dict[:var_16]
    )
end

function get_sys_state()
    response = HTTP.get(url*"/sys_state")
    if response.status == 200
        return sys_state_dict2struct(JSON3.read(response.body))
    else
        return nothing
    end
end

function show_messages()
    started = false
    last_time = 0.0
    while isnothing(get_sys_state())
        println("Waiting for start of simulation!")
        sleep(1)
    end

    while true
        ss = get_sys_state()
        if isnothing(ss)
            println("Simulation ended!")
            break
        end
        if ss.time > 0.0
            if !started
                println("Simulation started!")
                started = true
            end
            if ss.time != last_time
                println("time: ", round(ss.time, digits=2))
                if ss.time - last_time > 0.051
                    println("time step: ", round(ss.time - last_time, digits=2))
                end
                last_time = ss.time
            end
        end
        sleep(0.02)
    end
end

show_messages()

