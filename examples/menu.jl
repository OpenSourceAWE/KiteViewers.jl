using REPL.TerminalMenus

options = ["basic_1p = include(\"basic_1p.jl\")",
           "basic_4p = include(\"basic_4p.jl\")",
           "menus_4p = include(\"menus_4p.jl\")",
           "depower_bench_video = include(\"depower_bench_video.jl\")",
           "depower_simple = include(\"depower_simple.jl\")",
           "depower = include(\"depower.jl\")",
           "reelout1p = include(\"reelout_1p.jl\")",
           "reelout4p = include(\"reelout_4p.jl\")",
           "steering_4p = include(\"steering_4p.jl\")",
           "steering_bench_video = include(\"steering_bench_video.jl\")",
           "quit"]

function example_menu()
    active = true
    while active
        menu = RadioMenu(options, pagesize=8)
        choice = request("\nChoose function to execute or `q` to quit: ", menu)

        if choice != -1 && choice != length(options)
            eval(Meta.parse(options[choice]))
        else
            println("Left menu. Press <ctrl><d> to quit Julia!")
            active = false
        end
    end
end

example_menu()