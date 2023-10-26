
# API
EasyABM provides following functions for agent based simulations. 

## Functions for creating agents

```@docs
con_2d_agent
con_2d_agents
grid_2d_agent
grid_2d_agents
con_3d_agent
con_3d_agents
grid_3d_agent
grid_3d_agents
graph_agent
graph_agents
create_similar
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
run_model_epochs!
draw_frame
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
propnames
get_nums_agents 
get_nums_patches
get_nums_nodes 
get_nums_edges
get_agents_avg_props
get_patches_avg_props
get_nodes_avg_props
get_edges_avg_props
save_model
open_model
```

## Functions for creating and modifying a graph

```@docs
static_simple_graph
static_dir_graph
dynamic_simple_graph
dynamic_dir_graph
convert_type
hex_grid_graph
square_grid_graph
triangular_grid_graph
double_triangular_grid_graph
graph_from_dict
draw_graph
draw_graph3d
add_node!
add_nodes!
kill_node!
create_edge! 
kill_edge!
kill_all_edges!
flush_graph!
is_digraph
is_directed
is_static
vertices
edges
recompute_graph_layout
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
neighbors_moore
neighbors_neumann
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
neighbor_patches_moore
neighbor_patches_neumann
in_neighbor_nodes
out_neighbor_nodes
get_nodes
num_nodes
get_edges
num_edges
get_patches
num_patches
get_random_patch
random_empty_node
random_empty_patch
```

## Misc. utility functions

```@docs
dotprod
veclength
distance
calculate_direction
Col
@cl_str
moore_distance
manhattan_distance
set_window_size
```


## Index

```@index
```