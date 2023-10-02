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
                "Schellings Segregation 2D" => "schelling.md",
                "Flocking 2D" => "boids.md",
                "Rock-Paper-Scissor" => "stone_paper_scissor.md",
                "SIR model" => "SIR.md",
                "Predator-prey" => "predator_prey.md",
                "Conways Game of Life" => "conwaygol.md",
                "Random Walkers" => "random_walkers.md",
                "Schellings Segregation 3D" => "schelling3d.md",
                "Flocking 3D" => "boids3d.md",
                "Ising on a grid graph" => "ising.md",
                "Nearest Neighbor Graph" => "nearest_neighbor_graph.md",
                "Elementary Cellular Automaton" => "ElemCA.md",
                "Abelian Sandpile" => "abelian_sandpile.md",
                "Ising on a nearest neighbor graph" => "NNSIsing.md",
            ],
         "Do's and Don'ts" => "tips.md",
         "API" => "api.md",
        ]
         )
deploydocs(;
    repo="github.com/RenuSolanki/EasyABM.jl",
    branch="gh-pages"
)
