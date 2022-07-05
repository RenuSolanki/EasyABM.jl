
# Predator-prey model

```julia
using EasyABM
```

## Step 1: Create Agents and Model

We create 200 agents all of type `sheep` to begin with. Our model parameters are 

* `max_energy` : The maximum energy that an agent (sheep or wolf) can have. 
* `wolf_birth_rate` : Probability of a wolf agent to reproduce once its energy is greater than max_energy/2.  
* `sheep_birth_rate` : Probability of a wolf agent to reproduce once its energy is greater than max_energy/2. 
* `wolves_kill_ability` : The probability of a wolf to kill a neighboring sheep.
* `grass_grow_prob` : The probability of one unit of grass growing on a patch at a given timestep.
* `max_grass` : Max grass a patch can have.
* `initial_wolf_percent` : The percent of agents which are wolf initially. 

```julia
@enum agenttype sheep wolf
agents = grid_2d_agents(200, pos = Vect(1,1), color = :white, atype = sheep, 
    energy = 10.0, keeps_record_of=[:pos, :energy ])
model = create_2d_model(agents, size = (20,20), 
    agents_type = Mortal, # agents are mortal, can take birth or die
    space_type = NPeriodic, # nonperiodic space
    max_energy = 50, 
    wolf_birth_rate = 0.01,
    sheep_birth_rate = 0.1,
    wolves_kill_ability = 0.2,
    max_grass = 5,
    initial_wolf_percent = 0.2,
    grass_grow_prob = 0.2)
```

## Step 2: Initialise the model

In the second step we initialise the patches and agents by defining `initialiser!` function and sending it as an argument to `init_model!`. In the `initialiser!` function we randomly set amount of grass and accordingly color of each patch. We also set a fraction `initial_wolf_percent` of agents to be of type wolf. We set color of sheeps to white and that of wolves to black. We also randomly set the energy and positions of agents. In the `init_model!` function through argument `props_to_record` we tell EasyABM to record the color property of patches during model run. 


```julia
function initialiser!(model)
    max_grass = model.parameters.max_grass
    for j in 1:model.size[2]
        for i in 1:model.size[1]
            grass = rand(1:max_grass)
            model.patches[i,j].grass = grass
            hf = Int(ceil(max_grass/2))
            model.patches[i,j].color = grass > hf ? :green : (grass > 0 ? :blue : :grey)
        end
    end
    for agent in model.agents
        if rand()< model.parameters.initial_wolf_percent 
            agent.atype = wolf
            agent.color = :black
        else
            agent.atype = sheep
            agent.color = :white
        end
        agent.energy = rand(1:model.parameters.max_energy)+0.0
        agent.pos = Vect(rand(1:model.size[1]), rand(1:model.size[2]))
    end
            
end

init_model!(model, initialiser = initialiser!, props_to_record = Dict("patches"=>[:color]))
```

## Step 3: Run the model

In this step we implement the step logic of the predator prey model in the `step_rule!` function and run the model for 100 steps. 



```julia
function change_pos!(agent)
    dx = rand(-1:1)
    dy = rand(-1:1)
    agent.pos += Vect(dx, dy)
end

function reproduce!(agent, model)
    new_agent = create_similar(agent)
    agent.energy = agent.energy/2
    new_agent.energy = agent.energy
    add_agent!(new_agent, model)
end

function eat_sheep!(wolf, sheep, model)
    kill_agent!(sheep, model) 
    wolf.energy+=1
end


function act_asa_wolf!(agent, model)
    if !(is_alive(agent))
        return
    end
    energy = agent.energy
    if energy > 0.5*model.parameters.max_energy
        if rand()<model.parameters.wolf_birth_rate
            reproduce!(agent, model)
        end
    elseif energy > 0 
        nbrs = collect(grid_neighbors(agent, model, 1))
        n = length(nbrs)
        if n>0
            nbr = nbrs[rand(1:n)]
            if (nbr.atype == sheep)&&(is_alive(nbr))
                ability = model.parameters.wolves_kill_ability
                (rand()<ability)&&(eat_sheep!(agent, nbr, model))
            end
        end
        change_pos!(agent)
    else
        kill_agent!(agent, model)
    end
end

function act_asa_sheep!(agent, model)
    if !(is_alive(agent))
        return
    end
    energy = agent.energy
    if energy >0.5* model.parameters.max_energy
        if rand()<model.parameters.sheep_birth_rate
            reproduce!(agent, model)
        end
        change_pos!(agent)
    elseif energy > 0 
        patch = get_grid_loc(agent, model)
        grass = model.patches[patch...].grass
        if grass>0
            model.patches[patch...].grass-=1
            agent.energy +=1
        end
        change_pos!(agent)
    else
        kill_agent!(agent, model)
    end
end



function step_rule!(model)
    if model.max_id>800 # use some upper bound on max agents to avoid system hang
        return
    end
    for agent in model.agents
        if agent.atype == wolf
            act_asa_wolf!(agent,model)
        end
        if agent.atype == sheep
            act_asa_sheep!(agent, model)
        end
    end
    for j in 1:model.size[2]
        for i in 1:model.size[1]
            patch = model.patches[i,j]
            grass = patch.grass
            max_grass = model.parameters.max_grass 
            if grass < max_grass
                if rand()<model.parameters.grass_grow_prob
                    patch.grass+=1
                    hf = Int(ceil(max_grass/2))
                    patch.color = grass > hf ? :green : (grass > 0 ? :yellow : :grey)
                end
            end
        end
    end
end

run_model!(model, steps=100, step_rule = step_rule! )
```

If one wants to see the animation of the model run, it can be done as 

```julia
animate_sim(model, show_grid=true)
```

![png](assets/PPrey/PPreyAnim1.png)


After defining the `step_rule!` function we can also choose to create an interactive application (which currently works in Jupyter with WebIO installation) as 

```julia
create_interactive_app(model, initialiser= initialiser!,
    step_rule= step_rule!,
    model_controls=[
        (:wolf_birth_rate, :s, 0:0.01:1.0),
        (:sheep_birth_rate, :s, 0.01:0.01:1.0),
        (:initial_wolf_percent, :s, 0.01:0.01:0.9),
        (:wolves_kill_ability, :s, 0.01:0.01:1.0),
        (:grass_grow_prob, :s, 0.01:0.01:0.5)
        ], 
    agent_plots=Dict("sheep"=> agent-> agent.atype == sheep ? 1 : 0, 
        "wolf"=> agent-> agent.atype == wolf ? 1 : 0),
    frames=200, show_grid=true)
```

![png](assets/PPrey/PPreyIntApp.png)




## Step 4: Fetch Data 

We can fetch the number of wolves and sheeps at each time step as follows. 

```julia
df = get_nums_agents(model, agent-> agent.atype == sheep, 
    agent->agent.atype == wolf, labels=["Sheep", "Wolf"], 
    plot_result = true)
```

![png](assets/PPrey/PPreyPlot1.png)

Individual agent data recorded during model run can be obtained as 

```julia
df = get_agent_data(model.agents[1], model).record
```
    


