@testset "2d model A" begin
	ag = con_2d_agent(color=cl"white")
    ag1 = create_similar(ag, 2)
    ag2 = create_similar(ag)
    agents = con_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :pos, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Mortal, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        n = length(model.agents)
        if model.tick ==5
            kill_agent!(model.agents[rand(1:n)], model)
        end
        model.agents[1].pos += Vect(rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model, tail=(2, agent->agent.color==cl"red"))
    create_interactive_app(model)
    EasyABM.save_sim(model)
    save_model(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbors(model.agents[1], model)
    get_agent_data(model.agents[1], model)
    latest_propvals(model.agents[1], model, :color, 1)
    propnames(model.agents[1])
    get_model_data(model)
    get_nums_agents(model, ag->ag.color==cl"red")
    get_agents_avg_props(model, ag-> (ag.is_sick ? 0 : 1))
    get_nums_agents(model, ag->ag.is_sick)
end

@testset "2d model B" begin
    agents = grid_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :pos, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Static, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos = Vect(rand(1:5), rand(1:5))
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model, show_patches=true)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbor_patches_moore((1,1), model)
    neighbor_patches_moore(model.agents[1], model)
    neighbor_patches_neumann((1,1), model)
    neighbor_patches_neumann(model.agents[1], model)
    neighbors_moore(model.agents[1], model)
    neighbors_neumann(model.agents[1], model)
    get_patch_data((1,1), model)
    get_nums_patches(model, pt->pt.color==cl"white")
    get_patches_avg_props(model, pt->(pt.color==cl"white" ? 0 : 1))
end

@testset "2d model C" begin
    agents = con_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Static, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos += Vect(rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbors(model.agents[1], model)
    get_agent_data(model.agents[1], model)
    latest_propvals(model.agents[1], model, :color, 1)
    propnames(model.agents[1])
    get_model_data(model)
    get_nums_agents(model, ag->ag.color==cl"red")
    get_agents_avg_props(model, ag-> (ag.is_sick ? 0 : 1))
    get_nums_agents(model, ag->ag.is_sick)
end

@testset "2d model D" begin
    agents = grid_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Mortal, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        n = length(model.agents)
        if model.tick ==5
            kill_agent!(model.agents[rand(1:n)], model)
        end
        model.agents[1].pos = Vect(rand(1:5), rand(1:5))
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbors_moore(model.agents[1], model)
    neighbors_neumann(model.agents[1], model)
    get_patch_data((1,1), model)
    get_nums_patches(model, pt->pt.color==cl"white")
    get_patches_avg_props(model, pt->(pt.color==cl"white" ? 0 : 1))
end


###################################
@testset "2d model E" begin
    agents = con_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Mortal, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        n = length(model.agents)
        if model.tick ==5
            kill_agent!(model.agents[rand(1:n)], model)
        end
        model.agents[1].pos += Vect(rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbors(model.agents[1], model)
end

@testset "2d model F" begin
    agents = grid_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Static, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos = Vect(rand(1:5), rand(1:5))
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbors_moore(model.agents[1], model)
    neighbors_neumann(model.agents[1], model)
end

@testset "2d model G" begin
    agents = con_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Static, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos += Vect(rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbors(model.agents[1], model)
end

@testset "2d model H" begin
    agents = grid_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_2d_model(agents, size = (5,5), agents_type=Mortal, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        n = length(model.agents)
        if model.tick ==5
            kill_agent!(model.agents[rand(1:n)], model)
        end
        model.agents[1].pos = Vect(rand(1:5), rand(1:5))
    end
    @test run_model!(model, steps=steps, step_rule= step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
    neighbors_moore(model.agents[1], model)
    neighbors_neumann(model.agents[1], model)
end
