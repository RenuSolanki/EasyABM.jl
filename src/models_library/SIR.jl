# module SIR

# export prepare, run, data
# using ...Abmot  # .thing = thing inside same module, ..thing = inside parent module, ...thing = thing inside parent of parent module. 

# const _num_agents = 500
# const _initially_sick = 10
# const _sickness_duration = 21
# const _prob_death = 0.05
# const _infection_prob = 1.0
# const _steps = 200

# @enum AgentType begin
#     agentS=1
#     agentI=2
#     agentR=3
#     agentD=4
# end



# function prepare(; num_agents = _num_agents, initially_sick =_initially_sick, 
#     sickness_duration = _sickness_duration, pdeath = _prob_death,
#     infection_prob = _infection_prob)

#     function initmodel!(model)
#         for (i,agent) in enumerate(model.agents)
#             if i<=initially_sick
#                 agent.atype = agentI
#                 agent.color = :red
#             end
#         end
#     end

#     agents = create_2d_agents(num_agents, shape = :circle, 
#             color=:green, atype = agentS, not_well_since = 0);

#     model = create_2d_model(agents, grid_size=(50,50), periodic = true, random_positions=true, duration = sickness_duration, 
#             infectionprob = infection_prob, pdeath=pdeath);

#     init_model!(model, initialiser = initmodel!);

#     print("SIS model initialized. Infected agents are red circles and susceptible agents are represented as green.")

#     return model
# end


# function steprun!(agent, model)
#     parameters = model.parameters
#     nbrs = neighbors(agent, model, 1)
#     if agent.atype == agentI
#          agent.not_well_since +=1
#         if agent.not_well_since > parameters.duration
#             if rand()<parameters.pdeath
#                 agent.atype = agentD
#                 agent.color = :black
#             else
#                 agent.atype = agentR
#                 agent.color = :yellow
#             end
#         elseif agent.not_well_since>1
#             for nbr in nbrs
#                 if (nbr.atype ==agentS) && (rand()< parameters.infectionprob)
#                     nbr.atype = agentI
#                     nbr.not_well_since = 0
#                     nbr.color = :red
#                 end
#             end
#         end   
#     end
#     if agent.atype !=agentD
#         x,y=agent.pos
#         x+=rand()*rand(-1:1)
#         y+=rand()*rand(-1:1)
#         agent.pos = (x,y)
#     end
    
# end

# function run(model; steps=_steps, show_graphics = false)

#     run_model!(model, steps=steps, scheduler = :index, 
#             agent_step_function = steprun!, aprops = [:pos, :color, :atype]);
#     if show_graphics
#         animate_sim(model, steps)
#     end
# end

# function data(model; plot_result = true)
#     get_num_agents(model,agent->agent.atype ==agentS, agent->agent.atype == agentI, agent->agent.atype ==agentD,agent->agent.atype ==agentR, labels = ["Susceptible", "Infected", "Dead", "Recovered"], plot_result = plot_result)
# end


# end