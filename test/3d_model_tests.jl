@testset "3d model A" begin
    agents = con_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Mortal, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
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
        model.agents[1].pos += Vect(rand(),rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end

@testset "3d model B" begin
    agents = grid_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Static, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos = Vect(rand(1:4), rand(1:4), rand(1:4))
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end

@testset "3d model C" begin
    agents = con_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Static, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos += Vect(rand(),rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end

@testset "3d model D" begin
    agents = grid_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Mortal, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
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
        model.agents[1].pos = Vect(rand(1:4), rand(1:4), rand(1:4))
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end

############################################

@testset "3d model E" begin
    agents = con_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Mortal, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
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
        model.agents[1].pos += Vect(rand(),rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end

@testset "3d model F" begin
    agents = grid_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Static, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos = Vect(rand(1:4), rand(1:4), rand(1:4))
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end

@testset "3d model G" begin
    agents = con_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Static, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    @test init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> Set([:model_property1]))) == nothing
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        model.agents[1].pos += Vect(rand(),rand(),rand())
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end

@testset "3d model H" begin
    agents = grid_3d_agents(5, color=Col("red"), is_sick = false, shape = :sphere, keeps_record_of = Set([:color, :is_sick]))
    model = create_3d_model(agents, size = (4,4,4), agents_type = Mortal, space_type = NPeriodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
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
        model.agents[1].pos = Vect(rand(1:4), rand(1:4), rand(1:4))
    end
    @test run_model!(model, steps=steps, step_rule = step_rule!)==nothing
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    animate_sim(model)
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end