push!(LOAD_PATH,"../src/")
using Documenter, EasyABM
makedocs(
         sitename = "EasyABM.jl",
         modules  = [EasyABM],
         format = Documenter.HTML(),
         pages = ["Home" => "index.md",
         "Examples" => [
            "2d model" => "2d_model_example1.md",
            ],
         "API" => "api.md",
        ]
         )
deploydocs(;
    repo="github.com/RenuSolanki/EasyABM.jl",
)
