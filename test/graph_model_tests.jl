
@testset "graph model" begin
    mat = sparse([1,2,2,3,3,4,4,5,5,1],[2,1,3,2,4,3,5,4,1,5],[1,1,1,1,1,1,1,1,1,1]) # pentagon 1--2--3--4--5--1 #
    graph = create_simple_graph(mat)
    agents = graph_agents(5, node=2, color=:red, is_sick = false, shape = :circle, keeps_record_of = [:color, :is_sick])
    model = create_graph_model(agents, graph, static_graph = false, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
        for vert in get_nodes(model)
            model.graph.nodesprops[vert].color = :red
        end
    end
    init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> [:model_property1]))
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    @test model.graph.nodesprops[1].color == :red
    steps = 10
    function step_rule!(model)
        if model.tick == 1
            kill_node!(1, model)
        end
        if model.tick == 4
            kill_edge!(2,3, model)
        end
        if model.tick ==5
            ags = get_agents(model)
            n = length(ags)
            kill_agent!(ags[rand(1:n)], model)
        end
        if model.tick ==7
            add_node!(model)
        end
        if model.tick == 8
            create_edge!(3,7,model)
        end
    end
    run_model!(model, steps=steps, step_rule= step_rule!)
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end
