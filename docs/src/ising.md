
# Ising model

We use Ising model as an example of using Graph Models in EasyABM. We will set up and run Ising model on a grid graph, however one can choose graph of any other 
topology as well.

```julia
using EasyABM
```

## Step 1: Create Agents and Model

In this model we will work solely with the graph and won't reuire agents. We create a grid graph of size 20x20, an empty list of agents, and then create our graph model as follows. 

```julia
graph = square_grid(20,20); # We could also use graphs generated with Graphs.jl package. 
agents = create_graph_agents(0);
model = create_graph_model(agents, graph, temp = 0.1, coupl = 1.0)
```

The model has two parameters temperature `temp` and coupling `coupl`. 

## Step 2: Initialise the model

In the second step we initialise the nodes of the graph through `initialiser!` function and then sending it as an argument to `init_model!`. In the `initialiser!` function we randomly set each node's color to either `:black` or `:white` and set their spin values to +1 for `:black` nodes and -1 for `:white` nodes. In the `init_model!` function the argument `props_to_record` specifies the nodes properties which we want to record during model run. 

```julia
function initialiser!(model)
    for node in model.graph.nodes
        if rand()<0.5
            model.graph.nodesprops[node].spin = 1
            model.graph.nodesprops[node].color = :black
        else
            model.graph.nodesprops[node].spin = -1
            model.graph.nodesprops[node].color = :white
        end
    end
end

init_model!(model, initialiser = initialiser!, props_to_record = Dict("nodes"=>[:color, :spin]))
```

## Step 3: Run the model

In this step we implement the step logic of the Ising model in the `step_rule!` function and run the model for 200 steps. At each step of the simulation we take 
100 Monte Carlo steps, where in each Monte Carlo step a node is selected at random and its spin and color values are flipped is the Ising energy condition is satisfied. 



```julia
const nn = num_nodes(model) 

function step_rule!(model)
    for i in 1:100
        random_node = rand(1:nn)
        spin = model.graph.nodesprops[random_node].spin
        nbr_nodes = neighbor_nodes(random_node, model)
        de = 0.0
        for node in nbr_nodes
            nbr_spin = model.graph.nodesprops[node].spin
            de += spin*nbr_spin
        end
        de = 2*model.parameters.coupl * de
        if (de < 0) || (rand() < exp(-de/model.parameters.temp))
            model.graph.nodesprops[random_node].spin = - spin
            model.graph.nodesprops[random_node].color = spin == -1 ? :black : :white
        end
    end
end

run_model!(model, steps=200, step_rule = step_rule! )
```

If one wants to see the animation of the model run, it can be done as 

```julia
animate_sim(model)
```

![png](assets/Ising/IsingAnim1.png)

Note that the scale slider is for changing the size of agents. As we have zero agents in the current model, this slider won't do anything. 


Once the model has been run it can be saved to the disk as a jld2 file using following function.

```julia
save_model(model, model_name = "ising_model", save_as = "ising.jld2", folder = "/path/to/folder/")
```

A model saved previously as jld2 file, can be fetched as follows 

```julia
model = open_saved_model(model_name = "ising_model", path = "/path/to/folder/ising.jld2")
```

After defining the `step_rule!` function we can also choose to create an interactive application (which currently works in Jupyter with WebIO installation) as 

```julia
create_interactive_app(model, initialiser= initialiser!,
    props_to_record = Dict("nodes"=>[:color, :spin]),
    step_rule= step_rule!,
    model_controls=[(:temp, :s, 0.05:0.05:5), (:coupl, :s, 0.01:0.1:5)],
    node_plots = Dict("magnetisation"=> x -> x.spin),
    frames=200) 
```

![png](assets/Ising/IsingIntApp.png)




## Step 4: Fetch Data 

In this step we fetch the data of average spin of nodes (also called magnetisation) and plot the result as follows. 

```julia
df = get_nodes_avg_props(model, node -> node.spin, labels=["magnetisation"], plot_result = true)
```

![png](assets/Ising/IsingPlot1.png)




