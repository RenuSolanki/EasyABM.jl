
@testset "graph model A" begin
	ag =graph_agent(color=cl"red")
    create_similar(ag,1)
    create_similar(ag)
    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    graph = dynamic_simple_graph(mat)
    agents = graph_agents(5, node=2, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_graph_model(agents, graph, agents_type = Mortal, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
        for vert in get_nodes(model)
            model.graph.nodesprops[vert].color = Col("red")
        end
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    @test model.graph.nodesprops[1].color == Col("red")
    steps = 10
    function step_rule!(model)
        if model.tick == 1
            kill_node!(1, model)
        end
        if model.tick == 4
            kill_edge!(2,3, model)
        end
        if model.tick ==5
            ags = collect(get_agents(model))
            n = length(ags)
            kill_agent!(ags[rand(1:n)], model)
        end
        if model.tick ==7
            add_node!(model, color=cl"red")
        end
        if model.tick == 8
            create_edge!(3,7,model)
        end
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    create_interactive_app(model)
    draw_frame(model,frame=2)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    get_node_data(1, model)
    get_edge_data(1,2,model)
    get_nums_nodes(model, nd->nd.color==cl"red")
    get_nodes_avg_props(model, nd->(nd.color==cl"red" ? 0 : 1))
    get_nums_edges(model, edge->true)
    get_edges_avg_props(model, edge->1)
    
    
    gr=square_grid_graph(4,4)
    draw_graph(gr, mark_nodes=true)
    draw_graph3d(gr)
    gr=hex_grid_graph(4,4)
    gr=triangular_grid_graph(4,4)
    gr=double_triangular_grid_graph(4,4)
    gr=torus_graph(4,4)
    gr=graph_from_dict(Dict("num_nodes"=>2,
    "edges"=>[(1,2)],
    "is_directed"=>false,
    "is_dynamic"=>false,
    "positions"=>[(1.5,0.5),(0.5,1.5)],
    "positions3d"=>[(1.5,0.5,0.5),(0.5,1.5,0.5)],
    "colors"=>[cl"red",cl"red"],
    "sizes"=>[0.2,0.2]
    ))
    empty!(gr)
    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    graph=dynamic_simple_graph(mat)
    vertices(graph)
    edges(graph)
    EasyABM.out_links(graph, 1)
    EasyABM.has_edge(graph, 1, 2)
    EasyABM.has_edge(graph, (1,2))
    EasyABM._add_edge!(graph, 2,4)
    EasyABM._add_edge_f!(graph,2,5)
    EasyABM._add_edge_with_props!(graph, 1, 3)
    EasyABM._add_edge_with_props_f!(graph, 1, 4)
    EasyABM._add_vertex!(graph, 6)
    EasyABM._add_vertex_f!(graph, 7)
    EasyABM._add_vertex_with_props!(graph, 8)
    EasyABM._add_vertex_with_props_f!(graph, 9)
    EasyABM._rem_vertex!(graph, 9)
    EasyABM._rem_vertex_f!(graph, 8)
    EasyABM._num_edges_at(1, graph)
    EasyABM._rem_edge!(graph, 1, 3)
    EasyABM._rem_edge_f!(graph, 1, 4)
    EasyABM._set_edgeprops!(graph, 2, 4)
    EasyABM._set_edgeprops_f!(graph, 2, 5)
    EasyABM._set_vertexprops!(graph, 2)
    EasyABM._set_vertexprops_f!(graph, 2)

    EasyABM._structure_from_smat(mat)
    EasyABM.static_simple_graph(mat)
    EasyABM.adjacency_matrix(graph)
    EasyABM.combined_graph(graph, graph)
    EasyABM.combined_graph!(graph, deepcopy(graph))



    mat = sparse([1,2,3,4,5],[2,3,4,5,1],[1,1,1,1,1]) # pentagon 1-->2-->3-->4-->5-->1 #
    graph=dynamic_dir_graph(mat)
    vertices(graph)
    edges(graph)
    EasyABM.out_links(graph, 1)
    EasyABM.has_edge(graph, 1, 2)
    EasyABM.has_edge(graph, (1,2))
    EasyABM._add_edge!(graph, 2,4)
    EasyABM._add_edge_f!(graph,2,5)
    EasyABM._add_edge_with_props!(graph, 1, 3)
    EasyABM._add_edge_with_props_f!(graph, 1, 4)
    EasyABM._add_vertex!(graph, 6)
    EasyABM._add_vertex_f!(graph, 7)
    EasyABM._add_vertex_with_props!(graph, 8)
    EasyABM._add_vertex_with_props_f!(graph, 9)
    EasyABM._rem_vertex!(graph, 9)
    EasyABM._rem_vertex_f!(graph, 8)
    EasyABM._num_edges_at(1, graph)
    EasyABM._rem_edge!(graph, 1, 3)
    EasyABM._rem_edge_f!(graph, 1, 4)
    EasyABM._set_edgeprops!(graph, 2, 4)
    EasyABM._set_edgeprops_f!(graph, 2, 5)
    EasyABM._set_vertexprops!(graph, 2)
    EasyABM._set_vertexprops_f!(graph, 2)

    EasyABM._in_structure_from_smat(mat)
    EasyABM.static_dir_graph(mat)
    EasyABM.adjacency_matrix(graph)
    EasyABM.combined_graph!(graph, deepcopy(graph))
end



@testset "graph model B" begin
    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    graph = static_simple_graph(mat)
    graph = convert_type(graph, Static)
    agents = graph_agents(5, node=2, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_graph_model(agents, graph, agents_type = Static, vis_space="3d", random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
        for vert in get_nodes(model)
            model.graph.nodesprops[vert].color = Col("red")
        end
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    @test model.graph.nodesprops[1].color == Col("red")
    steps = 10
    function step_rule!(model)
        if model.tick ==5
            model.agents[1].node=rand(1:5)
        end
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    create_interactive_app(model)
    draw_frame(model,frame=2)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    get_node_data(1, model)
    get_edge_data(1,2,model)
    get_nums_nodes(model, nd->nd.color==cl"red")
    get_nodes_avg_props(model, nd->(nd.color==cl"red" ? 0 : 1))
    get_nums_edges(model, edge->true)
    get_edges_avg_props(model, edge->1)
end



@testset "graph model C" begin
    mat = sparse([1,2,3,4,5],[2,3,4,5,1],[1,1,1,1,1])
    graph = dynamic_dir_graph(mat)
    agents = graph_agents(5, node=2, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_graph_model(agents, graph, agents_type = Mortal, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
        for vert in get_nodes(model)
            model.graph.nodesprops[vert].color = Col("red")
        end
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    @test model.graph.nodesprops[1].color == Col("red")
    steps = 10
    function step_rule!(model)
        if model.tick == 1
            kill_node!(1, model)
        end
        if model.tick == 4
            kill_edge!(2,3, model)
        end
        if model.tick ==5
            ags = collect(get_agents(model))
            n = length(ags)
            kill_agent!(ags[rand(1:n)], model)
        end
        if model.tick ==7
            add_node!(model, color=cl"red")
        end
        if model.tick == 8
            create_edge!(3,7,model)
        end
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    create_interactive_app(model)
    draw_frame(model, frame=2)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    get_node_data(1, model)
    get_edge_data(1,2,model)
    get_nums_nodes(model, nd->nd.color==cl"red")
    get_nodes_avg_props(model, nd->(nd.color==cl"red" ? 0 : 1))
    get_nums_edges(model, edge->true)
    get_edges_avg_props(model, edge->1)
    
    
    gr=square_grid_graph(4,4)
    draw_graph(gr, mark_nodes=true)
    draw_graph3d(gr)
    gr=hex_grid_graph(4,4)
    gr=triangular_grid_graph(4,4)
    gr=double_triangular_grid_graph(4,4)
    gr=torus_graph(4,4)
    gr=graph_from_dict(Dict("num_nodes"=>2,
    "edges"=>[(1,2)],
    "is_directed"=>false,
    "is_dynamic"=>false,
    "positions"=>[(1.5,0.5),(0.5,1.5)],
    "positions3d"=>[(1.5,0.5,0.5),(0.5,1.5,0.5)],
    "colors"=>[cl"red",cl"red"],
    "sizes"=>[0.2,0.2]
    ))
end



@testset "graph model D" begin
    mat = sparse([1,2,3,4,5],[2,3,4,5,1],[1,1,1,1,1])
    graph = static_dir_graph(mat)
    graph = convert_type(graph, Static)
    agents = graph_agents(5, node=2, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_graph_model(agents, graph, agents_type = Static, vis_space="3d", random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
        for vert in get_nodes(model)
            model.graph.nodesprops[vert].color = Col("red")
        end
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    @test model.graph.nodesprops[1].color == Col("red")
    steps = 10
    function step_rule!(model)
        if model.tick ==5
            model.agents[1].node=rand(1:5)
        end
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    create_interactive_app(model)
    draw_frame(model, frame=2)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    get_node_data(1, model)
    get_edge_data(1,2,model)
    get_nums_nodes(model, nd->nd.color==cl"red")
    get_nodes_avg_props(model, nd->(nd.color==cl"red" ? 0 : 1))
    get_nums_edges(model, edge->true)
    get_edges_avg_props(model, edge->1)
end
