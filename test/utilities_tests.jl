@testset "utilities_neighbors" begin
    agents = create_2d_agents(5, pos = (1,1))
    model = create_2d_model(agents, grid_size = (10,10),periodic=false)
    @test Set(neighbors(model.agents[1], model))==Set(model.agents[2:5])   
    @test Set(neighbor_patches(model.agents[1], model, 1)) == Set([(1,2),(2,1),(2,2)])
    model = create_2d_model(agents, grid_size = (10,10),periodic=true)
    @test Set(neighbor_patches(model.agents[1], model, 1)) == Set([(1,2),(2,1),(2,2),(10,1),(1,10),(10,10),(2,10),(10,2)])
    model.agents[1].pos = (5,5)
    model.agents[2].pos = (5,6)
    model.agents[3].pos = (6,5)
    @test model.patches[5,6]._extras._agents == [2]
    @test Set(neighbors(model.agents[1], model, 1.5)) == Set(model.agents[2:3])
    @test Set(neighbors(model.agents[1], model, 1.5, metric = :euclidean)) == Set(model.agents[2:3])

    agents = create_3d_agents(5, pos = (1,1,1))
    model = create_3d_model(agents, grid_size = (5,5,5),periodic=false)
    @test Set(neighbors(model.agents[1], model))==Set(model.agents[2:5])   
    @test Set(neighbor_patches(model.agents[1], model, 1)) == Set([(1,1,2),(1,2,1),(2,1,1),(1,2,2),(2,1,2),(2,2,1),(2,2,2)])
    #model = create_3d_model(agents, grid_size = (5,5,5),periodic=true)
    # @test Set(neighbor_patches(model.agents[1], model, 1)) == Set([(1,1,2),(1,2,1),(2,1,1),(1,2,2),(2,1,2),(2,2,1),(2,2,2), (5,1,1),(1,5,1),(1,1,5),(5,2,2),(2,5,2),(2,2,5),(5,5,5)])
    model.agents[1].pos = (4,4,4)
    model.agents[2].pos = (4,4,3)
    model.agents[3].pos = (3,4,4)
    @test model.patches[4,4,3]._extras._agents == [2]
    @test Set(neighbors(model.agents[1], model, 1.1)) == Set(model.agents[2:3])
    @test Set(neighbors(model.agents[1], model, 1.1, metric = :euclidean)) == Set(model.agents[2:3])



    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    graph = create_simple_graph(mat)
    agents = create_graph_agents(5, color=:red, node = 1)
    model = create_graph_model(agents, graph, static_graph = false)
    model.agents[2].node = 3
    @test Set(neighbor_nodes(model.agents[2], model)) == Set([2,4])
    @test Set(neighbor_nodes(3, model)) == Set([2,4])
    kill_node!(2, model)
    @test neighbor_nodes(model.agents[2], model) == [4]
    mat = sparse([1,3,3,5,5,1],[2,2,4,4,1,5],[1,1,1,1,1,0]) # pentagon 1-->2<--3-->4<--5-->1 #
    graph = create_dir_graph(mat)
    agents = create_graph_agents(5, color=:red, node = 3)
    model = create_graph_model(agents, graph, static_graph = false)
    @test Set(neighbor_nodes(model.agents[1], model)) == Set([2,4])
    @test Set(neighbor_nodes(3, model)) == Set([2,4])
    @test in_neighbor_nodes(3, model) == Int[]
    model.agents[2].node = 4
    @test Set(in_neighbor_nodes(model.agents[2], model)) == Set([3,5])
    kill_node!(2, model)
    @test out_neighbor_nodes(3, model) == [4]
    model.agents[3].node = 4
    model.agents[4].node = 4
    model.agents[5].node = 4
    @test Set(out_neighbors(model.agents[1], model)) == Set(model.agents[2:5])
    @test Set(in_neighbors(model.agents[2], model)) == Set([model.agents[1], model.agents[3], model.agents[4], model.agents[5]])
end


@testset "utilities_more" begin
    agents = create_2d_agents(5, pos = (0.5,0.5), color=:red)
    model = create_2d_model(agents, grid_size = (2,2),periodic=false)
    model.agents[5].pos = (1.5,1.5)
    @test get_grid_loc(model.agents[5], model) == (2,2)
    @test is_occupied((2,2), model) == true
    @test agents_at((2,2), model)[1] == model.agents[5]
    @test num_agents_at((2,2), model) == 1
    model.agents[5].pos = (1.5,0.5)
    @test is_occupied((2,1), model) == true
    @test is_occupied((2,2), model) == false
    for i in 1:3
        model.agents[i].color = :blue
    end
    @test num_agents(model, agent->agent.color==:red)==2
    @test Set(get_agents(model, agent->agent.color==:red)) == Set([model.agents[4], model.agents[5]])
    kill_agent!(model.agents[1], model)
    @test is_alive(model.agents[1]) == false
    @test num_agents(model, agent->agent.color==:blue)==2
    @test Set(get_agents(model, agent->agent.color==:blue)) == Set([model.agents[2], model.agents[3]])
    set_patchprops!((1,1), model, color = :blue, sick = true)
    set_patchprops!((1,2), model, color = :white, sick = false)
    set_patchprops!((2,1), model, color = :pink, sick = false)
    set_patchprops!((2,2), model, color = :blue, sick = true)
    @test get_patchprop(:color, (1,1), model) == :blue
    @test get_patchprop(:sick, (1,1), model) == true
    @test num_patches(model, patch->patch.color == :blue) == 2
    @test Set(get_patches(model, patch->patch.color == :blue)) == Set([(1,1),(2,2)])

    agents = create_3d_agents(5, pos = (0.5,0.5,0.5))
    model = create_3d_model(agents, grid_size = (2,2,2),periodic=false)
    model.agents[5].pos = (1.5,1.5,1.5)
    @test get_grid_loc(model.agents[5], model) == (2,2,2)
    @test is_occupied((2,2,2), model) == true
    @test agents_at((2,2,2), model)[1] == model.agents[5]
    @test num_agents_at((2,2,2), model) == 1
    model.agents[5].pos = (1.5,0.5,0.5)
    @test is_occupied((2,1,1), model) == true
    @test is_occupied((2,2,2), model) == false
    for i in 1:3
        model.agents[i].color = :blue
    end
    @test num_agents(model, agent->agent.color==:red)==2
    @test Set(get_agents(model, agent->agent.color==:red)) == Set([model.agents[4], model.agents[5]])
    kill_agent!(model.agents[1], model)
    @test is_alive(model.agents[1]) == false
    @test num_agents(model, agent->agent.color==:blue)==2
    @test Set(get_agents(model, agent->agent.color==:blue)) == Set([model.agents[2], model.agents[3]])
    set_patchprops!((1,1,1), model, color = :blue, sick = true)
    set_patchprops!((1,1,2), model, color = :blue, sick = true)
    set_patchprops!((1,2,1), model, color = :blue, sick = true)
    set_patchprops!((1,2,2), model, color = :blue, sick = true)
    set_patchprops!((2,1,1), model, color = :pink, sick = false)
    set_patchprops!((2,1,2), model, color = :pink, sick = false)
    set_patchprops!((2,2,1), model, color = :white, sick = false)
    set_patchprops!((2,2,2), model, color = :white, sick = false)
    @test get_patchprop(:color, (1,1,1), model) == :blue
    @test get_patchprop(:sick, (2,1,2), model) == false
    @test num_patches(model, patch->patch.color == :blue) == 4
    @test Set(get_patches(model, patch->patch.color == :blue)) == Set([(1,1,1),(1,1,2),(1,2,1),(1,2,2)])

    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    graph = create_simple_graph(mat)
    agents = create_graph_agents(5, color=:red, node = 1)
    model = create_graph_model(agents, graph, static_graph = false)
    model.agents[5].node = 2
    @test get_node_loc(model.agents[5], model) == 2
    @test is_occupied(2, model) == true
    @test agents_at(2, model)[1] == model.agents[5]
    @test num_agents_at(2, model) == 1
    model.agents[5].node = 3
    @test is_occupied(3, model) == true
    @test is_occupied(2, model) == false
    for i in 1:3
        model.agents[i].color = :blue
    end
    @test num_agents(model, agent->agent.color==:red)==2
    @test Set(get_agents(model, agent->agent.color==:red)) == Set([model.agents[4], model.agents[5]])
    set_nodeprops!(1, model, color = :blue, sick = true)
    set_nodeprops!(2, model, color = :blue, sick = true)
    set_nodeprops!(3, model, color = :pink, sick = false)
    set_nodeprops!(4, model, color = :pink, sick = false)
    set_nodeprops!(5, model, color = :white, sick = false)
    set_edgeprops!((1,2), model, weight = 1)
    set_edgeprops!((3,2), model, weight = 1)
    set_edgeprops!((3,4), model, weight = 2)
    set_edgeprops!((4,5), model, weight = 2)
    set_edgeprops!((5,1), model, weight = 3)
    @test get_nodeprop(:color, 1, model) == :blue 
    @test get_edgeprop(:weight, (1,2), model) == 1
    @test get_edgeprop(:weight, (5,4), model) == 2
    @test num_nodes(model, node -> node.color ==:blue) == 2
    @test Set(get_nodes(model, node -> node.color == :pink)) == Set([3,4])
    @test num_edges(model, edge -> edge.weight == 1) == 2
    @test Set(get_edges(model, edge -> edge.weight == 1)) == Set([(1,2),(2,3)])



    mat = sparse([1,3,3,5,5,1],[2,2,4,4,1,5],[1,1,1,1,1,0]) # pentagon 1-->2<--3-->4<--5-->1 #
    graph = create_dir_graph(mat)
    agents = create_graph_agents(5, color=:red, node = 1)
    model = create_graph_model(agents, graph, static_graph = false)
    model.agents[5].node = 2
    @test get_node_loc(model.agents[5], model) == 2
    @test is_occupied(2, model) == true
    @test agents_at(2, model)[1] == model.agents[5]
    @test num_agents_at(2, model) == 1
    model.agents[5].node = 3
    @test is_occupied(3, model) == true
    @test is_occupied(2, model) == false
    for i in 1:3
        model.agents[i].color = :blue
    end
    @test num_agents(model, agent->agent.color==:red)==2
    @test Set(get_agents(model, agent->agent.color==:red)) == Set([model.agents[4], model.agents[5]])
    set_nodeprops!(1, model, color = :blue, sick = true)
    set_nodeprops!(2, model, color = :blue, sick = true)
    set_nodeprops!(3, model, color = :pink, sick = false)
    set_nodeprops!(4, model, color = :pink, sick = false)
    set_nodeprops!(5, model, color = :white, sick = false)
    set_edgeprops!((1,2), model, weight = 1)
    set_edgeprops!((3,2), model, weight = 1)
    set_edgeprops!((3,4), model, weight = 2)
    set_edgeprops!((5,4), model, weight = 2)
    set_edgeprops!((5,1), model, weight = 3)
    @test get_nodeprop(:color, 1, model) == :blue 
    @test get_edgeprop(:weight, (1,2), model) == 1
    @test get_edgeprop(:weight, (5,4), model) == 2
    @test num_nodes(model, node -> node.color ==:blue) == 2
    @test Set(get_nodes(model, node -> node.color == :pink)) == Set([3,4])
    @test num_edges(model, edge -> edge.weight == 1) == 2
    @test Set(get_edges(model, edge -> edge.weight == 1)) == Set([(1,2),(3,2)])
end



# create_2d_agent, create_2d_agents, create_graph_agent, 
# create_graph_agents, create_3d_agent, create_3d_agents,
# create_2d_model, create_graph_model, create_3d_model,
# # initialise, run, visualise
# init_model!, run_model!, run_model_epochs!, animate_sim, 
# create_interactive_app, save_model, open_saved_model,

# # data 
# get_agent_data, get_patch_data, get_node_data,
# get_edge_data, get_model_data, latest_propvals, get_nums_agents, get_nums_patches,
# get_nums_nodes, get_nums_edges, get_agents_avg_props, get_patches_avg_props,
# get_nodes_avg_props, get_edges_avg_props,

# #helpers graph
# create_simple_graph, create_dir_graph, 
# hex_grid, square_grid, triangular_grid, 
# double_triangular_grid, draw_graph,
# adjacency_matrix, add_node!, kill_node!, 
# create_edge!, kill_edge!, is_digraph, is_static,


# #helpers 2d/3D

# #agent
# get_grid_loc, get_node_loc, get_id, agents_at, num_agents_at, agent_with_id, is_alive,
# get_agents, num_agents, kill_agent!, add_agent!,


# #patches, nodes, edges
# is_occupied, get_nodeprop, get_edgeprop, set_nodeprops!, 
# set_edgeprops!, get_patchprop, set_patchprops!, 
# neighbor_nodes, neighbor_patches, in_neighbor_nodes, out_neighbor_nodes, 
# get_nodes, num_nodes, get_edges, num_edges, get_patches, num_patches, 
# random_empty_node, random_empty_patch, 

# #neighbor agents
# neighbors, in_neighbors, out_neighbors, 

# #misc utilities
# dotproduct, norm, distance, calculate_direction,
