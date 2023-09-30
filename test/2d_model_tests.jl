@testset "2d model" begin
    agents = con_2d_agents(5, color=Col("red"), is_sick = false, shape = :circle, keeps_record_of = Set([:color, :is_sick]))
    model = create_2d_model(agents, grid_size = (5,5), agents_type=Mortal, space_type = Periodic, random_positions = true, model_property1 = 0.7, model_property2 = "nice_model")
    function initialiser!(model)
        model.agents[1].shape = :box
        model.agents[5].is_sick = true
    end
    init_model!(model, initialiser=initialiser!, props_to_record = Dict("model"=> [:model_property1]))
    @test model.agents[1].shape == :box
    @test model.agents[5].is_sick == true
    steps = 10
    function step_rule!(model)
        n = length(model.agents)
        if model.tick ==5
            kill_agent!(model.agents[rand(1:n)], model)
        end
    end
    run_model!(model, steps=steps, step_rule= step_rule!)
    data = get_agent_data(model.agents[1], model).record
    datam= get_model_data(model).record
    @test length(data[!,:color])==steps+1 #initial data is also recorded
    @test length(data[!,:is_sick])==steps+1
    @test length(datam[!,:model_property1]) == steps+1
end