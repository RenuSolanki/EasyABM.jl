
# Stone Paper Scissor

```julia
using EasyABM
```

## Step 1: Create Model

In this model, we work with patches instead of agents. As agents is the first field required in the `create_2d_model` function, so for syntactical correctness we create a list of 0 agents, and use it as first argument of `create_2d_model` function. We set `grid_size` to (50,50), set `periodic` to true and define an additional model parameter `threshold` whose value is set to 2. 

```julia
agents = create_2d_agents(0) 
model = create_2d_model(agents, grid_size = (50,50), threshold = 2, periodic = true)
```

## Step 2: Initialise the model

In the second step we initialise the agents by defining `initialiser!` function and sending it as an argument to `init_model!`. In the `initialiser!` function randomly assign `:red` (for stone), `:green` (for paper) and `:blue` (for scissor) color to patches. Then we initialise the model using `init_model!` function, in which through the argument `props_to_record`, we tell EasyABM to record the `:color` property of patches during time evolution. Note that, in EasyABM animations are created with the recorded data, therefore if in the present model, the color of patches is not recorded there will there will be no animation to see. 


```julia
function initialiser!(model)
    for j in 1:model.size[2]
        for i in 1:model.size[1]
            num = rand()
            if num<0.33
                model.patches[i,j].color = :red # stone => red, paper => green, scissor => blue
            elseif num>0.66
                model.patches[i,j].color = :green
            else
                model.patches[i,j].color = :blue
            end
        end
    end
end

init_model!(model, initialiser = initialiser!, props_to_record = Dict("patches" => [:color]))
```

## Step 3: Run the model

In this step we define the `step_rule!` function and run the model for 400 steps. The rule of the game is very simple. The `:red` color of a patch will change to `:green` if number of neighboring patches with color `:green` exceeds the threshold( which we set to be 2 in the beginning). Similarly, if a `:green` patch finds larger than the threshold number of `:blue` patches in its neighborhood, it will change to `:blue`, and if a `:blue` patch finds larger than threshold number of `:red` patches in its neighborhood it will change to `:red`. Each step of the model consists of 500 Monte-Carlo steps in which a patch is selected at random and the above mentioned rule applied to it. 

```julia
const who_wins_against = Dict(:red => :green, :green => :blue, :blue => :red)

function step_rule!(model)
    for _ in 1:500
        i = rand(1:model.size[1])
        j = rand(1:model.size[2])
        nbr_patches = neighbor_patches((i,j), model, 1)
        col = model.patches[i,j].color
        winner_col = who_wins_against[col]
        count = 0 
        for patch in nbr_patches
            if model.patches[patch...].color == winner_col
                count+=1
            end
        end
        if count > model.parameters.threshold
            model.patches[i,j].color = winner_col
        end
    end
end

run_model!(model, steps = 400, step_rule = step_rule!)
```

If one wants to see the animation of the model run, it can be done as 

```julia
animate_sim(model, show_grid=true)
```

![png](assets/StonePaperScissor/SPSAnim1.png)

Once the model has been run it can be saved to the disk as a jld2 file using following function.

```julia
save_model(model, model_name = "sps_model", save_as = "stone_paper_scissor.jld2", folder = "/path/to/folder/")
```

A model saved previously as jld2 file, can be fetched as follows 

```julia
model = open_saved_model(model_name = "sps_model", path = "/path/to/folder/stone_paper_scissor.jld2")
```

After defining the `step_rule!` function we can also choose to create an interactive application (which currently works in Jupyter with WebIO installation) as 

```julia
create_interactive_app(model, initialiser= initialiser!,
    props_to_record = Dict("patches" => [:color]),
    step_rule= step_rule!,
    model_controls=[(:threshold, :s, 1:8)], 
    frames=400, show_grid=true) 
```

![png](assets/StonePaperScissor/SPSIntApp.png)




## Step 4: Fetch Data 

It is easy to fetch any recorded data after running the model. For example, the numbers of different colored patches at all timesteps can be got as follows

```julia
df = get_nums_patches(model, 
    patch-> patch.color ==:red, 
    patch-> patch.color ==:green, 
    patch-> patch.color ==:blue, labels=["stone","paper","scissor"], plot_result=true)
```

![png](assets/StonePaperScissor/SPSPlot1.png)

    


