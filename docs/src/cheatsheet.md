## Continuous space agents and model in 2D

Example: Following code creates 100 continuous space 2D agents, and then a 2D model containing them. 

```julia
agents = con_2d_agents(100, pos = Vect(5.0,5.0), color = cl"yellow", keeps_record_of = Set([:pos]))
model = create_2d_model(agents, force = 2.0, dt=0.1)
```

## Continuous space agents and model in 3D

Example: Following code creates 100 continuous space 3D agents, and then a 3D model containing them. 

```julia
agents = con_3d_agents(100, pos = Vect(5.0,5.0,5.0), color = cl"yellow", keeps_record_of = Set([:pos]))
model = create_3d_model(agents, force = 2.0, dt=0.1)
```

## Discrete space agents and model in 2D

Example: Following code creates 100 discrete space 2D agents, and then a 2D model containing them. 

```julia
agents = grid_2d_agents(100, pos = Vect(5,5), color = cl"yellow", keeps_record_of = Set([:pos]))
model = create_2d_model(agents, size=(20,20) force = 2.0, dt=0.1) # there will be a 20x20 grid of patches. By default a 2d model (discrete as well as continuous) has a 10x10 grid of patches.
```

## Discrete space agents and model in 3D

Example: Following code creates 100 discrete space 3D agents, and then a 3D model containing them. 

```julia
agents = grid_3d_agents(100, pos = Vect(5,5,5), color = cl"yellow", keeps_record_of = Set([:pos]))
model = create_3d_model(agents, size=(20,20,20), force = 2.0, dt=0.1) # there will be a 20x20x20 grid of patches. By default a 3d model (discrete as well as continuous) has a 10x10x10 grid of patches.
```

## Graph space agents and model

Example: Following code creates a 10x10 square grid graph, 100 graph space agents, and a graph space model containing them. 

```julia
graph = square_grid_graph(10,10)
agents = graph_agents(100, node=1, color = cl"yellow", keeps_record_of = Set([:node])) # agents live on graph nodes, so instead of :pos they have :node property
model = create_graph_model(agents, graph, force = 2.0, dt=0.1) 
```

## Agents type - Mortal vs Static

A model can have Static agents or Mortal agents. Static agents do not reproduce nor die. Mortal agents can die and reproduce. The mortality type of agents can be specified via `agents_type` argument in the function for creating model and its default value is Static. E.g. in the following code `agents_type` is set to `Mortal`.

```julia
agents = con_2d_agents(100, pos = Vect(5.0,5.0), color = cl"yellow", keeps_record_of = Set([:pos]))
model = create_2d_model(agents, agents_type=Mortal, force = 2.0, dt=0.1) 
```

## Space type - Periodic vs NPeriodic

A 2D or 3D space model can have periodic or non-periodic boundary conditions. This can be specified via `space_type` argument in the function for creating model and its default value is Periodic. E.g. in the following code `space_type` is set to NPeriodic. 

```julia
agents = con_3d_agents(100, pos = Vect(5.0,5.0,5.0), color = cl"yellow", keeps_record_of = Set([:pos]))
model = create_3d_model(agents, space_type=NPeriodic, force = 2.0, dt=0.1) 
```

## Graph space - Dynamic vs Static

A graph can be Dynamic (nodes/edges can be added or removed) or Static (nodes/edges can not be added or removed). In the following code we create a 10x10 dynamic grid graph, create 100 graph agents and then a graph model containing them. 

```julia
graph = square_grid_graph(10,10, dynamic=true)
agents = graph_agents(100, node=1, color = cl"yellow", keeps_record_of = Set([:node])) # agents live on graph nodes, so instead of :pos they have :node property
model = create_graph_model(agents, graph, force = 2.0, dt=0.1) 
```

## Graph space - Directed vs Simple

In EasyABM we call a graph Directed if its edges are directed, otherwise we call it Simple. In the following code we create a model with a directed graph that has two nodes 1,2 and edge 1->2 between them.

```julia
graph = graph_from_dict(
    Dict(
    "num_nodes"=>2,
    "is_directed"=>true,
    "edges"=>[(1,2)]
    )
)
agents = graph_agents(100, node=1, color = cl"yellow", keeps_record_of = Set([:node])) # agents live on graph nodes, so instead of :pos they have :node property
model = create_graph_model(agents, graph, force = 2.0, dt=0.1) 
```

## Initialization, running, visualization, fetching data
After defining agents and the model, the processes of initialization, running, visualization and fetching data are same for all model types. These steps use common functions like `init_model!`, `run_model!`, `animate_sim`, `draw_frame`, `get_agent_data` etc. For more details please refer to the [api](api.md).  

