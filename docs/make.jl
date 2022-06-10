push!(LOAD_PATH,"../src/")
using Documenter, EasyABM
makedocs(
         sitename = "EasyABM.jl",
         modules  = [EasyABM],
         format = Documenter.HTML(),
         pages = ["Introduction" => "index.md",
         "Tutorial" => "tutorial.md",
         "Examples" => [
            "2D Examples" => [
                "Schellings Segregation model" => "schelling.md",
                "Flocking" => "boids.md",
                "Rock-Paper-Scissor" => "stone_paper_scissor.md",
                "SIR model" => "SIR.md",
                "Predator-prey" => "predator_prey.md",
                "Conways Game of Life" => "conwaygol.md",

                ],
                
            "3D Examples" => [
                "Schellings Segregation model" => "schelling3d.md",
                "Flocking" => "boids3d.md",
                ],

            "Graph Space Examples" => [
                "Ising model" => "ising.md",
                ],
            
            ],
         "API" => "api.md",
        ]
         )
deploydocs(;
    repo="github.com/RenuSolanki/EasyABM.jl.git",
)
