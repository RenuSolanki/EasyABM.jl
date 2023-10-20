module EasyABM

export  Static, Mortal, PropDict, Vect,
        Periodic, NPeriodic,
        gparams, gparams3d,
        #create agents and models
        con_2d_agent, con_2d_agents, 
        grid_2d_agent, grid_2d_agents,
        con_3d_agent, con_3d_agents,
        grid_3d_agent, grid_3d_agents,
        graph_agent, graph_agents, 
        create_similar, 
        create_2d_model, create_graph_model, create_3d_model,
        
        # initialise, run, visualise
        init_model!, run_model!, run_model_epochs!, 
        draw_frame, animate_sim, set_screen!, 
        create_interactive_app, save_model, open_model,

        # data 
        get_agent_data, get_patch_data, get_node_data,
        get_edge_data, get_model_data, latest_propvals, 
        propnames, get_nums_agents, get_nums_patches,
        get_nums_nodes, get_nums_edges, get_agents_avg_props, get_patches_avg_props,
        get_nodes_avg_props, get_edges_avg_props,
        
        #helpers graph
        static_simple_graph, static_dir_graph, 
        dynamic_simple_graph, dynamic_dir_graph, convert_type,
        hex_grid_graph, square_grid_graph, triangular_grid_graph, 
        double_triangular_grid_graph, graph_from_dict, draw_graph,
        adjacency_matrix, add_node!, add_nodes!, kill_node!, 
        create_edge!, kill_edge!, kill_all_edges!, flush_graph!,
        is_digraph, is_directed, is_static,
        vertices, recompute_graph_layout,


        #helpers 2d/3D

        #agent
        get_grid_loc, get_node_loc, get_id, agents_at, num_agents_at, agent_with_id, is_alive,
        get_agents, num_agents, kill_agent!, add_agent!,


        #patches, nodes, edges
        is_occupied, get_nodeprop, get_edgeprop, set_nodeprops!, 
        set_edgeprops!, get_patchprop, set_patchprops!, 
        neighbor_nodes, neighbor_patches_moore, neighbor_patches_neumann, 
        in_neighbor_nodes, out_neighbor_nodes, 
        get_nodes, num_nodes, get_edges, num_edges, get_patches, get_random_patch, num_patches, 
        random_empty_node, random_empty_patch, 

        #neighbor agents
        neighbors, in_neighbors, out_neighbors, neighbors_moore, neighbors_neumann,

        #misc utilities
        dotprod, veclength, distance, calculate_direction, Col, @cl_str, moore_distance,
        manhattan_distance, set_window_size

        #inbuilt models
    
        


using Luxor, DataFrames, StatsBase, SparseArrays
using Plots:plot
import Plots
using Graphs
using JLD2
using FixedPointNumbers
using Random
using GeometryBasics
using MeshCat, CoordinateTransformations, Rotations
using Colors: RGBA, RGB
using DocStringExtensions
using Interact
using Scratch
#using Thebes
using Blink
using Base.Threads


include("abstracttypes.jl")
include("vec.jl")
include("colordef.jl")
include("savejld2.jl")

include("agents/generaldefs.jl")
include("agents/propdict.jl")
include("agents/propdatadict.jl")
include("agents/containerdatadict.jl")
include("agents/agent2d.jl")
include("agents/agent2dgrid.jl")
include("agents/agentgr.jl")
include("agents/agent3d.jl")
include("agents/agent3dgrid.jl")

include("utilitiesgeneral.jl")
include("helperfunctionsGeneral.jl")
include("datahandlingGeneral.jl")
include("graphicscommon.jl")


include("2d_model/model.jl")
include("2d_model/graphicsrelatedfuncs.jl")
include("2d_model/utilities.jl")
include("2d_model/helperfunctions.jl")
include("2d_model/datahandling.jl")
include("2d_model/mainfunctions.jl")


include("3d_model/model.jl")
#include("3d_model/Shapes.jl")
#using .Shapes
include("3d_model/graphicsrelatedfuncs.jl")
include("3d_model/utilities.jl")
include("3d_model/helperfunctions.jl")
include("3d_model/datahandling.jl")
include("3d_model/mainfunctions.jl")


include("graph_model/propgraphs.jl")
include("graph_model/model.jl")
include("graph_model/graphicsrelatedfuncs.jl")
include("graph_model/graphics3drelatedfuncs.jl")
include("graph_model/utilities.jl")
include("graph_model/helperfunctions.jl")
include("graph_model/graphplotlayouts.jl")
include("graph_model/datahandling.jl")
include("graph_model/mainfunctions.jl")


end # end of module


   
