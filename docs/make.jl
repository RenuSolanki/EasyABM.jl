push!(LOAD_PATH,"../src/")
push!(LOAD_PATH,"../docs/")

using Documenter, DocStringExtensions, EasyABM
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
                "Random Walkers" => "random_walkers.md",
                ],
                
            "3D Examples" => [
                "Schellings Segregation model" => "schelling3d.md",
                "Flocking" => "boids3d.md",
                ],

            "Graph Space Examples" => [
                "Ising model" => "ising.md",
                "Nearest Neighbor Graph" => "nearest_neighbor_graph.md",
                "Ising on a nearest neighbor graph" => "NNSIsing.md",
                ],
            
            ],
         "Do's and Don'ts" => "tips.md",
         "API" => "api.md",
        ]
         )
deploydocs(;
    repo="github.com/RenuSolanki/EasyABM.jl",
    branch="gh-pages"
)
