module EasyABM

export  StaticType, MortalType, PropDict, gparams, gparams3d,
        #create agents and models
        create_2d_agent, create_2d_agents, create_graph_agent, 
        create_graph_agents, create_3d_agent, create_3d_agents,
        create_2d_model, create_graph_model, create_3d_model,
        # initialise, run, visualise
        init_model!, run_model!, animate_sim, create_interactive_app, 

        # data 
        get_agent_data, get_patch_data, get_node_data,
        get_edge_data, get_model_data, get_nums_agents, get_nums_patches,
        get_nums_nodes, get_nums_edges,
        
        #helpers graph
        create_simple_graph, create_dir_graph, adjacency_matrix, add_node!, kill_node!, 
        create_edge!, kill_edge!,

        #helpers 2d/3D

        #agent
        get_grid_loc, get_node_loc, get_id, agents_at, num_agents_at, agent_with_id, is_alive,
        get_agents, num_agents, kill_agent!, add_agent!,


        #patches, nodes, edges
        is_occupied, get_nodeprop, get_edgeprop, set_nodeprops!, 
        set_edgeprops!, get_patchprop, set_patchprops!, 
        neighbor_nodes, neighbor_patches, in_neighbor_nodes, out_neighbor_nodes, 
        get_nodes, num_nodes, get_edges, num_edges, get_patches, num_patches, 
        random_empty_node, random_empty_patch, 

        #neighbor agents
        neighbors, in_neighbors, out_neighbors, 

        #inbuilt
        SIR   
    
        


using Luxor, DataFrames, StatsBase, SparseArrays
using Plots:plot
using Graphs
using JLD2
using Random
using GeometryBasics
using MeshCat, CoordinateTransformations, Rotations
using Colors: RGBA, RGB
using DocStringExtensions
using Interact
using Scratch
using CairoMakie



include("abstracttypes.jl")
include("savejld2.jl")

include("agents/generaldefs.jl")
include("agents/propdict.jl")
include("agents/propdatadict.jl")
include("agents/agent2d.jl")
include("agents/agentgr.jl")
include("agents/agent3d.jl")

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
include("3d_model/graphicsrelatedfuncs.jl")
include("3d_model/utilities.jl")
include("3d_model/helperfunctions.jl")
include("3d_model/datahandling.jl")
include("3d_model/mainfunctions.jl")


include("graph_model/propgraphs.jl")
include("graph_model/model.jl")
include("graph_model/graphicsrelatedfuncs.jl")
include("graph_model/utilities.jl")
include("graph_model/helperfunctions.jl")
include("graph_model/graphplotlayouts.jl")
include("graph_model/datahandling.jl")
include("graph_model/mainfunctions.jl")

include("models_library/SIR.jl")

end # end of module


   
