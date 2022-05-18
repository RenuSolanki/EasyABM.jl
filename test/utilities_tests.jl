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
    @test model.patches[(5,6)]._extras._agents == [2]
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
    @test model.patches[(4,4,3)]._extras._agents == [2]
    @test Set(neighbors(model.agents[1], model, 1.1)) == Set(model.agents[2:3])
    @test Set(neighbors(model.agents[1], model, 1.1, metric = :euclidean)) == Set(model.agents[2:3])



    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    graph = create_simple_graph(mat)
    agents = create_graph_agents(5, color=:red, node = 1)
    model = create_graph_model(agents, graph, static_graph = false)
    model.agents[2].node = 3
    @test Set(neighbor_nodes(model.agents[2], model)) == Set([2,4])
    @test Set(neighbor_nodes(3, model)) == Set([2,4])
    remove_node!(2, model)
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
    remove_node!(2, model)
    @test out_neighbor_nodes(3, model) == [4]
    model.agents[3].node = 4
    model.agents[4].node = 4
    model.agents[5].node = 4
    @test Set(out_neighbors(model.agents[1], model)) == Set(model.agents[2:5])
    @test in_neighbors(model.agents[2], model) == [model.agents[1]]
end


@testset "utilities_get_set" begin
    agents = create_2d_agents(5, pos = (1,1), color=:red)
    model = create_2d_model(agents, grid_size = (10,10),periodic=false)
    set_patchprops!((5,5), model, color = :blue, sick = true)
    @test get_patchprop(:color, (5,5), model) == :blue
end