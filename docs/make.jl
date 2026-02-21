using Documenter, KiteViewers

makedocs(;
    sitename = "KiteViewers.jl",
    modules  = [KiteViewers],
    pages = [
        "Home" => "index.md",
        "Reference" => "reference.md",
    ],
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
)

deploydocs(;
    repo = "github.com/OpenSourceAWE/KiteViewers.jl.git",
    devbranch = "main",
)
