"""
$(TYPEDSIGNATURES)
"""
@inline function dotproduct(a::GeometryBasics.Vec, b::GeometryBasics.Vec)
    sum = 0.0
    for (x,y) in zip(a,b)
        sum+=x*y
    end
    return sum
end

"""
$(TYPEDSIGNATURES)
"""
@inline function dotproduct(a::NTuple{N, Union{Integer, AbstractFloat}}, b::NTuple{N, Union{Integer, AbstractFloat}}) where N
    sum = zero(eltype(a))
    for (x,y) in zip(a,b)
        sum+=x*y
    end
    return sum
end

"""
$(TYPEDSIGNATURES)
"""
@inline function norm(a::GeometryBasics.Vec)
    return sqrt(dotproduct(a,a))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function norm(a::NTuple{N, Union{Integer, AbstractFloat}}) where N
    return sqrt(dotproduct(a,a))
end


"""
$(TYPEDSIGNATURES)
"""
@inline function distance(a::GeometryBasics.Vec, b::GeometryBasics.Vec)
    return norm(a-b)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function distance(a::NTuple{N, Union{Integer, AbstractFloat}}, b::NTuple{N, Union{Integer, AbstractFloat}}) where N
    return norm(a .- b)
end

Base.:+(x::GeometryBasics.Vec{N,<:Real},y::NTuple{N,Union{Integer, AbstractFloat}} ) where N = x .+ y
Base.:-(x::GeometryBasics.Vec{N,<:Real},y::NTuple{N,Union{Integer, AbstractFloat}} ) where N = x .- y

Base.:+(x::NTuple{N,Union{Integer, AbstractFloat}},y::GeometryBasics.Vec{N,<:Real}) where N = x .+ y
Base.:-(x::NTuple{N,Union{Integer, AbstractFloat}},y::GeometryBasics.Vec{N,<:Real}) where N = x .- y


Base.:+(x::NTuple{N,Union{Integer, AbstractFloat}},y::NTuple{N,Union{Integer, AbstractFloat}} ) where N = x .+ y
Base.:-(x::NTuple{N,Union{Integer, AbstractFloat}},y::NTuple{N,Union{Integer, AbstractFloat}} ) where N = x .- y 

Base.:*(x::NTuple{N,Union{Integer, AbstractFloat}},y::Real ) where N = x .* y
Base.:*(x::Real,y::NTuple{N,Union{Integer, AbstractFloat}} ) where N = x .* y 

Base.:/(x::NTuple{N,Union{Integer, AbstractFloat}},y::Real ) where N = x ./ y




@inline function _create_props_lists(aprops::Vector{Symbol}, pprops::Vector{Symbol}, mprops::Vector{Symbol}, model::AbstractSpaceModel)
    for sym in aprops
        if !(sym in model.record.aprops)
            push!(model.record.aprops, sym)
        end
    end

    if length(model.record.aprops)>0
        for agent in model.agents
            unwrap(agent)[:keeps_record_of] = model.record.aprops
        end
    end

    for sym in pprops
        if !(sym in model.record.pprops)
            push!(model.record.pprops, sym)
        end
    end
    for sym in mprops
        if !(sym in model.record.mprops)
            push!(model.record.mprops, sym)
        end
    end
end



@inline function _create_props_lists(aprops::Vector{Symbol}, nprops::Vector{Symbol}, eprops::Vector{Symbol}, mprops::Vector{Symbol}, model::AbstractGraphModel)

    empty!(model.record.aprops)
    for sym in aprops
        push!(model.record.aprops, sym)
    end

    if length(aprops)>0
        for agent in model.agents
            unwrap(agent)[:keeps_record_of] = copy(aprops)
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
    return vcat(model.agents, model.parameters._extras._agents_killed)

end

@inline function _get_all_agents(model::Union{AbstractSpaceModel{StaticType}, AbstractGraphModel{T, StaticType} }) where T<:MType
    return model.agents
end

"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function _permanently_remove_inactive_agents!(model::Union{AbstractSpaceModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    newly_added = model.parameters._extras._agents_added
    len_dead = length(model.parameters._extras._agents_killed)
    if len_dead>0
        for i in len_dead:-1:1
            agent = model.parameters._extras._agents_killed[i]
            aid = agent._extras._id
            if agent._extras._death_time == model.tick
                if agent in newly_added
                    deleteat!(newly_added, findfirst(m->m._extras._id==aid, newly_added))
                else
                    deleteat!(model.agents, findfirst(m->m._extras._id==aid, model.agents))
                    model.parameters._extras._len_model_agents -= 1
                end     
            else
                break
            end
        end
        if !(model.parameters._extras._keep_deads_data)
            empty!(model.parameters._extras._agents_killed)
            if length(newly_added)>0
                getfield(model,:max_id)[] = max([ag._extras._id for ag in newly_added]...)
            else
                len = model.parameters._extras._len_model_agents
                getfield(model,:max_id)[] = len > 0 ? model.agents[len]._extras._id : 0
            end
        end
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function commit_add_agents!(model::Union{AbstractSpaceModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    agents_to_add = model.parameters._extras._agents_added
    for ag in agents_to_add
        push!(model.agents, ag)
        model.parameters._extras._len_model_agents +=1
    end
    empty!(model.parameters._extras._agents_added)
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
            push!(model_data[key], model_dict[key])
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
@inline function _manage_default_data!(agent::AbstractPropDict, model::AbstractSpaceModel{MortalType})
    push!(model.parameters._extras._agents_added, agent)
    agent._extras._id = getfield(model,:max_id)[]+1
    agent._extras._active = true
    agent._extras._birth_time = model.tick
    agent._extras._death_time = Inf
    if model.parameters._extras._random_positions               
        _set_pos!(agent, model.size...)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _manage_default_data!(agent::AbstractPropDict, model::AbstractGraphModel{T, MortalType}) where T<:MType
    push!(model.parameters._extras._agents_added, agent)
    agent._extras._id = getfield(model,:max_id)[]+1
    agent._extras._active = true
    agent._extras._birth_time = model.tick
    agent._extras._death_time = Inf
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _create_agent_record!(agent::AbstractPropDict, model::Union{AbstractSpaceModel, AbstractGraphModel})
    if length(model.record.aprops)>0
        unwrap(agent)[:keeps_record_of] = model.record.aprops
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _init_agent_record!(agent::AbstractPropDict)
    agent_data = unwrap_data(agent)
    for key in agent.keeps_record_of
        agent_data[key] = [getproperty(agent, key)]
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _update_agent_record!(agent::AbstractPropDict)
    agent_data = unwrap_data(agent)
    for key in agent.keeps_record_of
        push!(agent_data[key], getproperty(agent, key))
    end
end




"""
$(TYPEDSIGNATURES)
"""
function _init_agents!(model::AbstractSpaceModel{MortalType})
    _permanently_remove_inactive_agents!(model)
    commit_add_agents!(model)
    empty!(model.parameters._extras._agents_killed)
    len = model.parameters._extras._len_model_agents 
    getfield(model,:max_id)[] = len > 0 ? model.agents[len]._extras._id : 0
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
@inline function _kill_agent!(agent::AbstractPropDict, push_to, tick)
        agent._extras._active= false
        agent._extras._death_time = tick
        push!(push_to, agent)
end

"""
$(TYPEDSIGNATURES)

Sets the agent as inactive thus effectively removing from the model. However, the removed agents 
are permanently removed from the list `model.agents` only twice in one step i) After the `agent_step_function` 
has run for all agents and ii) After the `step_rule`.
"""
function kill_agent!(agent::AbstractPropDict, model::AbstractSpaceModel{MortalType})
    if agent._extras._active
        gloc = get_grid_loc(agent, model)
        deleteat!(model.patches[gloc...]._extras._agents, findfirst(m->m==agent._extras._id, model.patches[gloc...]._extras._agents))
        _kill_agent!(agent, model.parameters._extras._agents_killed, model.tick)
        model.parameters._extras._num_agents -= 1
    end
end


"""
$(TYPEDSIGNATURES)

Sets the agent as inactive thus effectively removing from the model. However, the removed agents 
are permanently removed from the list `model.agents` only after each step.
"""
function kill_agent!(agent::AbstractPropDict, model::AbstractGraphModel{T,MortalType}) where T<:MType
    if agent._extras._active
        if haskey(agent, :node)
            x = agent._extras._last_node_loc
            deleteat!(model.graph.nodesprops[x]._extras._agents, findfirst(m->m==agent._extras._id, model.graph.nodesprops[x]._extras._agents))
        end
        _kill_agent!(agent, model.parameters._extras._agents_killed, model.tick)
        model.parameters._extras._num_agents -= 1
    end
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




