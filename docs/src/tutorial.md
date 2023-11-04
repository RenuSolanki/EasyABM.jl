# Tutorial

Studying an agents based model in EasyABM is basically a 5-step process. 

1. Create agents and model. 
2. Initialise the model, using the `init_model!` function.
3. Define a `step_rule` function and run the model. 
4. Visualisation which can be achieved simply by running `animate_sim(model)`. One can alo explore the model through an interactive app that can be created using the function `create_interactive_app`. 
5. Fetch and analyse data collected during model run. 

We explain these steps below through a very simple model of a star-planet system. Though it can be debated if a star-planet system can really qualify as an agent based model, it nevertheless serves as a good example for demonstrating the workings of EasyABM. 

## Step 1: Create the agents and the model.

In the first step we create the agents and the model. For the star-planet system, we need one agent for the star and one for the planet. We will assume that the star is stationary and the planet revolves around it. We set the position of the star to be Vect(5.0,5.0) which is the center point of the 2d space, as the default dimensions of 2d space in EasyABM is 10x10. The position `pos` is only accepted as a Vect which is an inbuilt vector type in EasyABM. It is also recommended for both convenience as well as performance to use Vect type for any vectorial properties in the model such as velocity and forces. We set the position of the planet to be Vect(7.0,5.0) and its velocity to be Vect(0.0,1.0). Since, the planet will change its position we require it to record its position and velocity during the model run. We specify this via `keeps_record_of` argument in the function for creating agent(s). We also have user defined model properties `gravity` and `dt` which stand for the force of gravity and small time interval between position and velocity updates respectively. 

```julia
star = con_2d_agent( pos = Vect(5.0,5.0), size = 0.15, color = cl"yellow") # by default 2d space is 10x10, so that (5,5) is center.
planet = con_2d_agent(pos = Vect(7.0,5.0), vel = Vect(0.0,1.0), size=0.05, color = cl"blue", keeps_record_of = Set([:pos, :vel])) 
model = create_2d_model([star, planet], gravity = 3.0, dt=0.1)
```

## Step 2: Initialise the model.

In this step we define an initialiser function to set the initial properties of the agents. Suppose we want our planet to be at position Vect(5.0,8.0) and velocity Vect(-1.0, 0.0) initially. We can do so by defining an initialiser function and then sending it as an argument to `init_model!` function as follows.

```julia
function initialiser!(model)
    planet = model.agents[2]
    planet.pos = Vect(5.0, 8.0)
    planet.vel = Vect(-1.0,0.0)
end

init_model!(model, initialiser = initialiser!)
```

## Step 3: Define a `step_rule` and run the model

In this step, we define rule for the time evolution and then run the model. We define our `step_rule` to be simply discretisation of Newton's equations for a 2 body system.

```julia
function step_rule!(model)
    gravity = model.properties.gravity
    dt = model.properties.dt
    star = model.agents[1]
    planet = model.agents[2]
    distance_vector = (star.pos - planet.pos)
    distance = veclength(distance_vector)
    force = gravity*distance_vector/distance^3
    planet.vel += force*dt
    planet.pos+= planet.vel*dt
end
```
Now we can run the model for desired number of steps as follows

```julia
run_model!(model, steps = 200, step_rule = step_rule!)
```

## Step 4: Visualisation

In order to draw the model at a specific frame, say 4th, one can use `draw_frame(model, frame = 4)`. We can look at the animation of the time evolution with following line of code

```julia
animate_sim(model,tail = (30, agent -> agent.color == cl"blue")) 
```
The tail argument attaches a tail of length 30 to the agent whose color is blue, which in our case is the planet. 


![png](assets/StarPlanetSystem/StarPlanetAnim1.png)


The model can be saved to the disk as a jld2 file using following function.

```julia
save_model(model, model_name = "sun_planet_model", save_as = "sun_planet.jld2", folder = "/path/to/folder/")
```

A model saved previously as jld2 file, can be fetched as follows 

```julia
model = open_model(model_name = "sun_planet_model", path = "/path/to/folder/sun_planet.jld2")
```

Instead of first running the model, we can create an interactive app in Jupyter notebook to explore the model by setting different values of properties, as shown below. It is recommended to define a fresh model and not initialise it with `init_model!` or run with `run_model!` before creating interactive app. The `model_control` argument asks EasyABM to create a slider with values from 1 to 5 in steps of 0.2 for the model parameter `gravity`. The agent_controls argument creates a slider for the x component of planet's initial velocity. The tail argument attaches a tail of length 30 with the planet by selecting it with its color property which we previously set to `cl"blue"`. 

```julia
star = con_2d_agent( pos = Vect(5.0,5.0), size = 0.15, color = cl"yellow") 

planet = con_2d_agent(pos = Vect(7.0,5.0), vel = Vect(0.0,1.0), size=0.05, color = cl"blue", keeps_record_of = Set([:pos, :vel])) 

model = create_2d_model([star, planet], gravity = 3.0, dt=0.1)

create_interactive_app(model, initialiser= initialiser!,
    step_rule= step_rule!,
    model_controls=[(:gravity, "slider", 1:0.2:5.0)], 
    agent_controls=[(:vel, "slider", [Vect(x, 0.0) for x in -10.0:0.1:5.0])],
    frames=200, tail = (30, agent -> agent.color == cl"blue")) 
```

![png](assets/StarPlanetSystem/StarPlanetIntApp.png)



## Step 5: Fetch data

In this simple model, the only data we have collected is the position and velocity of the planet. We can get this data as follows. 

```julia
df = get_agent_data(model.agents[2], model).record
```

The following line of code returns the data of (half of the) speed of the planet during time evolution.

```julia 
df = get_agents_avg_props(model, agent -> agent.color == cl"blue" ? veclength(agent.vel) : 0.0, labels = ["Planet Speed/2"], plot_result = true)   
```

![png](assets/StarPlanetSystem/SPSPlot1.png)




