"""
$(TYPEDSIGNATURES)
"""
@inline function dotprod(a::Vect{N}, b::Vect{N}) where N
    sum = 0.0
    for (x,y) in zip(a,b)
        sum+=x*y
    end
    return sum
end

"""
$(TYPEDSIGNATURES)
"""
@inline function dotprod(a::NTuple{N, <:Union{Integer, Float64}}, b::NTuple{N, <:Union{Integer, Float64}}) where N
    sum = 0.0
    for (x,y) in zip(a,b)
        sum+=x*y
    end
    return sum
end

"""
$(TYPEDSIGNATURES)
"""
@inline function dotprod(a::T, b::T) where T<:Union{AbstractAgent2D, AbstractAgent3D}
    vec = a.pos .- b.pos
    return dotprod(vec, vec)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function veclength(a::GeometryBasics.Vec)
    return sqrt(dotprod(a,a))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function veclength(a::NTuple{N, <:Union{Integer, Float64}}) where N
    return sqrt(dotprod(a,a))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function veclength(a::Vect{N}) where N
    return sqrt(dotprod(a,a))
end



"""
$(TYPEDSIGNATURES)
"""
@inline function distance(a::GeometryBasics.Vec, b::GeometryBasics.Vec)
    return veclength(a-b)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function distance(a::NTuple{N, Union{Integer, Float64}}, b::NTuple{N, Union{Integer, Float64}}) where N
    return veclength(a .- b)
end






@inline function _create_props_lists(aprops::Set{Symbol}, pprops::Set{Symbol}, mprops::Set{Symbol}, model::AbstractSpaceModel)

    empty!(model.record.aprops)
    for sym in aprops
        push!(model.record.aprops, sym)
    end

    if length(model.record.aprops)>0
        for agent in model.agents
            unwrap(agent)[:_keeps_record_of] = copy(aprops)
        end
    end

    empty!(model.record.pprops)
    for sym in pprops
        push!(model.record.pprops, sym)
    end

    empty!(model.record.mprops)
    for sym in mprops
        push!(model.record.mprops, sym)
    end
end



@inline function _create_props_lists(aprops::Set{Symbol}, nprops::Set{Symbol}, eprops::Set{Symbol}, mprops::Set{Symbol}, model::AbstractGraphModel)

    empty!(model.record.aprops)
    for sym in aprops
        push!(model.record.aprops, sym)
    end

    if length(aprops)>0
        for agent in model.agents
            unwrap(agent)[:_keeps_record_of] = copy(aprops)
        end
    end

    empty!(model.record.mprops)
    for sym in mprops
        push!(model.record.mprops, sym)
    end
 
    empty!(model.record.nprops)
    for sym in nprops
        push!(model.record.nprops, sym)
    end

    empty!(model.record.eprops)
    for sym in eprops
        push!(model.record.eprops, sym)
    end

end


@inline function _get_all_agents(model::Union{AbstractSpaceModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    return vcat(model.agents, model.agents_killed) # this function is not expected to be called from within a step function. 

end

@inline function _get_all_agents(model::Union{AbstractSpaceModel{StaticType}, AbstractGraphModel{T, StaticType} }) where T<:MType
    return model.agents
end

"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function _permanently_remove_inactive_agents!(model::Union{AbstractSpaceModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    newly_added = model.agents_added
    len_dead = length(model.agents_killed)
    if len_dead>0
        for i in len_dead:-1:1
            agent = model.agents_killed[i]
            aid = getfield(agent, :id)
            if agent._extras._death_time::Int == model.tick
                if agent in newly_added
                    deleteat!(newly_added, findfirst(m->getfield(m, :id)==aid, newly_added))
                else
                    deleteat!(model.agents, findfirst(m->getfield(m, :id)==aid, model.agents))
                    model.parameters._extras._len_model_agents::Int -= 1
                end     
            else
                break
            end
        end
    end
end




"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function commit_add_agents!(model::Union{AbstractSpaceModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    agents_to_add = model.agents_added
    for ag in agents_to_add
        push!(model.agents, ag)
        model.parameters._extras._len_model_agents::Int +=1
    end
    empty!(model.agents_added)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _init_model_record!(model::Union{AbstractSpaceModel, AbstractGraphModel})
    if length(model.record.mprops)>0
        model_dict = unwrap(model.parameters)
        model_data = unwrap_data(model.parameters)
        for key in model.record.mprops
            model_data[key]= [model_dict[key]]
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _update_model_record!(model::Union{AbstractSpaceModel, AbstractGraphModel})
    if length(model.record.mprops)>0
        model_dict = unwrap(model.parameters)
        model_data = unwrap_data(model.parameters)
        for key in model.record.mprops
            push!(model_data[key]::Vector, model_dict[key])
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _random_vector(t::NTuple{N,Int}) where N
    lst = Float64[]
    for i in t
        push!(lst, rand()*i)
    end
    return tuple(lst...)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _manage_default_data!(agent::AbstractAgent, model::AbstractSpaceModel{MortalType})
    push!(model.agents_added, agent)
    id = getfield(model,:max_id)[]+1
    setfield!(agent, :id, id)
    agent._extras._new = false
    agent._extras._active = true
    agent._extras._birth_time = model.tick
    agent._extras._death_time = typemax(Int)
    if model.parameters._extras._random_positions::Bool           
        _set_pos!(agent, model.size...)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _manage_default_data!(agent::AbstractAgent, model::AbstractGraphModel{T, MortalType}) where T<:MType
    push!(model.agents_added, agent)
    id = getfield(model,:max_id)[]+1
    setfield!(agent, :id, id)
    agent._extras._new = false
    agent._extras._active = true
    agent._extras._birth_time = model.tick
    agent._extras._death_time = typemax(Int)
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _create_agent_record!(agent::AbstractAgent, model::Union{AbstractSpaceModel, AbstractGraphModel})
    if length(model.record.aprops)>0
        unwrap(agent)[:_keeps_record_of] = copy(model.record.aprops)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _init_agent_record!(agent::AbstractAgent)
    agent_data = unwrap_data(agent)
    for key in agent._keeps_record_of::Set{Symbol}
        agent_data[key] = [getproperty(agent, key)]
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _update_agent_record!(agent::AbstractAgent)
    agent_data = unwrap_data(agent)
    for key in agent._keeps_record_of::Set{Symbol}
        push!(agent_data[key], getproperty(agent, key))
    end
end




"""
$(TYPEDSIGNATURES)
"""
function _init_agents!(model::AbstractSpaceModel{MortalType})
    _permanently_remove_inactive_agents!(model)
    empty!(model.agents_killed)
    commit_add_agents!(model)
    len = model.parameters._extras._len_model_agents::Int
    getfield(model,:max_id)[] = len > 0 ? getfield(model.agents[len], :id) : 0
    for agent in model.agents
        agent._extras._birth_time = 1
        _init_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)
"""
function _init_agents!(model::AbstractSpaceModel{StaticType})
    for agent in model.agents
        _init_agent_record!(agent)
    end
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _kill_agent!(agent::AbstractAgent, push_to, tick)#internal use
        agent._extras._active= false
        agent._extras._death_time = tick
        push!(push_to, agent)
end

"""
$(TYPEDSIGNATURES)

Sets the agent as inactive thus effectively removing from the model. However, the removed agents 
are permanently removed from the list `model.agents` only once after the `step_rule`.
"""
function kill_agent!(agent::AbstractAgent, model::AbstractSpaceModel{MortalType})
    if agent._extras._active::Bool
        gloc = get_grid_loc(agent)
        id = getfield(agent, :id)
        deleteat!(model.patches[gloc...].agents, findfirst(m->m == id, model.patches[gloc...].agents))
        _kill_agent!(agent, model.agents_killed, model.tick)
        model.parameters._extras._num_agents::Int -= 1
    end
end

_static_agents_error() = throw(error("Number of static agents is fixed. Set agents_type = MortalType in model definition."))
_static_graph_error() = throw(error("A static graph can not be modified. Use a dynamic graph in model definition."))

"""
$(TYPEDSIGNATURES)
"""
function kill_agent!(agent::AbstractAgent, model::AbstractSpaceModel{StaticType})
    _static_agents_error()
end

"""
$(TYPEDSIGNATURES)
"""
function add_agent!(agent, model::AbstractSpaceModel{StaticType})
    _static_agents_error()
end

"""
$(TYPEDSIGNATURES)

Sets the agent as inactive thus effectively removing from the model. However, the removed agents 
are permanently removed from the list `model.agents` only after each step.
"""
function kill_agent!(agent::AbstractAgent, model::AbstractGraphModel{T,MortalType}) where T<:MType
    if agent._extras._active::Bool
        x=agent.node
        id = getfield(agent, :id)
        deleteat!(model.graph.nodesprops[x].agents, findfirst(m->m==id, model.graph.nodesprops[x].agents))
        _kill_agent!(agent, model.agents_killed, model.tick)
        model.parameters._extras._num_agents::Int -= 1
    end
end


"""
$(TYPEDSIGNATURES)
"""
function kill_agent!(agent::AbstractAgent, model::AbstractGraphModel{T,StaticType}) where T<:MType
    _static_agents_error()
end


"""
$(TYPEDSIGNATURES)
"""
function add_agent!(agent, model::AbstractGraphModel{T,StaticType}) where T<:MType
    _static_agents_error()
end


"""
$(TYPEDSIGNATURES)

"""
@inline function _run_sim!(model::Union{AbstractSpaceModel, AbstractGraphModel }, steps,
    step_rule::Function) 
 
    for step in 1:steps
        step_rule(model)
        do_after_model_step!(model)     
    end
end


@inline function loss_of_data_prompt()
    println("Any data collected during previous model run will be lost.")
    print("Want to continue ? y/n :  ")

    flush(stdout)

    u_res = readline()

    return !(u_res in ["y", "Y"])
end




