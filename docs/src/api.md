
# API
EasyABM provides following functions for agent based simulations. 

## Functions for creating agents

```@docs
create_2d_agent
create_2d_agents
create_3d_agent
create_3d_agents
create_graph_agent
create_graph_agents
```

## Functions for defining model

```@docs
create_2d_model
create_3d_model
create_graph_model
```

## Functions for initialising, running and visualising

```@docs
init_model!
run_model!
animate_sim
create_interactive_app
```

## Functions for accessing, saving and retrieving data.

```@docs
get_agent_data 
get_patch_data 
get_node_data
get_edge_data 
get_model_data 
latest_propvals
get_nums_agents 
get_nums_patches
get_nums_nodes 
get_nums_edges
get_agents_avg_props
get_patches_avg_props
get_nodes_avg_props
get_edges_avg_props
save_model
open_saved_model
```

## Functions for creating and modifying a graph

```@docs
create_simple_graph
create_dir_graph
add_node!
kill_node!
create_edge! 
kill_edge!
```

## Helper functions for agents

```@docs
get_grid_loc
get_node_loc
get_id
agents_at
num_agents_at
agent_with_id
is_alive
get_agents 
num_agents 
kill_agent!
add_agent!
```

## Functions for getting neighbor agents.

```@docs
neighbors
in_neighbors
out_neighbors
```

## Helper functions for patches, nodes, edges

```@docs
is_occupied
get_nodeprop
get_edgeprop
set_nodeprops!
set_edgeprops!
get_patchprop
set_patchprops!
neighbor_nodes
neighbor_patches
in_neighbor_nodes
out_neighbor_nodes
get_nodes
num_nodes
get_edges
num_edges
get_patches
num_patches
random_empty_node
random_empty_patch
```

## Misc. utility functions

```@docs
dotproduct
norm
distance
calculate_direction
```


## Index

```@index
```