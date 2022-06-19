# Flocking

```julia
using EasyABM
```

## Step 1: Create Agents and Model

Lets create 200 agents with properties `shape`, `pos`, `vel` and `orientation` (The `orientation` property is used internally by EasyABM to draw the direction agent is facing). The `keeps_record_of` argument is list of properties that the agent will record during time evolution. The model is defined with parameters:

* min_dis : The distance between boids below which they start repelling each other.
* coh_fac : The proportionality constant for the cohere force. 
* sep_fac : The proportionality constant for the separation force.
* aln_fac : The proportionality constant for the alignment force.
* vis_range : The visual range of boids.
* dt : The proportionality constant between change in position and velocity.

The argument `fix_agents_num` is set to true which means that the boids number will remain fixed during simulation. 

```julia
boids = con_2d_agents(200, shape = :arrow, pos = (0.0,0.0), 
    vel=(0.0,0.0), orientation = 0.0, keeps_record_of = [:pos, :vel, :orientation])
model = create_2d_model(boids,fix_agents_num=true, min_dis = 0.3, coh_fac = 0.05, 
    sep_fac = 0.5, dt= 0.1, vis_range = 2.0, aln_fac = 0.35, periodic = true)
```

## Step 2: Initialise the model

In this step we set the positions, velocities and orientations of boids and initialise the model.


```julia
function initialiser!(model)
    xdim, ydim = model.size
    for boid in model.agents
        boid.pos = (rand()*xdim, rand()*ydim)
        boid.orientation = rand()*2*3.14
        boid.vel = (-sin(boid.orientation), cos(boid.orientation))
    end
end

init_model!(model, initialiser = initialiser!)
```

## Step 3: Run the model

In this step we implement the step logic of the flocking model in the `step_rule!` function and run the model for 500 steps. 



```julia

using GeometryBasics # used to represent forces as Vec

const ep = 0.00001

function step_rule!(model)
    dt = model.parameters.dt
    for boid in model.agents
        nbrs = neighbors(boid, model, model.parameters.vis_range)
        coh_force = Vec(0.0,0) 
        sep_force = Vec(0.0,0) 
        aln_force = Vec(0.0,0)
        num = 0
        for nbr in nbrs
            num+=1
            vec = nbr.pos - boid.pos
            coh_force += vec
            if norm(vec)< model.parameters.min_dis
                sep_force -= vec
            end
            aln_force += nbr.vel
        end
        aln_force = num>0 ? (aln_force/ num - boid.vel)*model.parameters.aln_fac : aln_force
        num = max(1, num)
        coh_force *= (model.parameters.coh_fac/num)
        sep_force *=  model.parameters.sep_fac
        boid.vel  += (coh_force + sep_force) + aln_force
        boid.vel  /= (norm(boid.vel)+ep)
        boid.orientation = calculate_direction(boid.vel)
        boid.pos += boid.vel*dt
    end
end

run_model!(model, steps=500, step_rule = step_rule!)
```

If one wants to see the animation of the model run, it can be done as 

```julia
animate_sim(model)
```

![png](assets/Boids/BoidsAnim1.png)


After defining the `step_rule!` function we can also choose to create an interactive application (which currently works in Jupyter with WebIO installation) as 

```julia
create_interactive_app(model, initialiser= initialiser!,
    step_rule= step_rule!,
    model_controls=[(:min_dis, :s, 0.01:0.1:1.0),
        (:coh_fac, :s, 0.01:0.01:1.0),
        (:sep_fac, :s, 0.01:0.01:1.0),
        (:aln_fac, :s, 0.01:0.01:1.0),
        (:vis_range, :s, 0.5:0.5:4.0)], frames=400) 
```

![png](assets/Boids/BoidsIntApp.png)




## Step 4: Fetch Data 

It is easy to fetch any data recorded during simulation. For example, the data of average velocity of agents at each time step can be obtained as - 

```julia
df = get_agents_avg_props(model, agent -> agent.vel, labels = ["average velocity"])
```

Individual agent data recorded during model run can be obtained as 

```julia
df = get_agent_data(model.agents[1], model).record
```