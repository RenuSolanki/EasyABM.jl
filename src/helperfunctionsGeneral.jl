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
@inline function norm(a::GeometryBasics.Vec)
    return sqrt(dotproduct(a,a))
end


"""
$(TYPEDSIGNATURES)
"""
@inline function distance(a::GeometryBasics.Vec, b::GeometryBasics.Vec)
    return norm(a-b)
end

Base.:+(x::GeometryBasics.Vec{3,Float64},y::NTuple{3,Union{Float64,Int}} ) = GeometryBasics.Vec(x[1]+y[1], x[2]+y[2], x[3]+y[3])
Base.:+(x::GeometryBasics.Vec{2,Float64},y::NTuple{2,Union{Float64,Int}} ) = GeometryBasics.Vec(x[1]+y[1], x[2]+y[2])
Base.:-(x::GeometryBasics.Vec{3,Float64},y::NTuple{3,Union{Float64,Int}} ) = GeometryBasics.Vec(x[1]-y[1], x[2]-y[2], x[3]-y[3])
Base.:-(x::GeometryBasics.Vec{2,Float64},y::NTuple{2,Union{Float64,Int}} ) = GeometryBasics.Vec(x[1]-y[1], x[2]-y[2])

Base.:+(x::NTuple{3,Union{Float64,Int}},y::GeometryBasics.Vec{3,Float64}) = GeometryBasics.Vec(x[1]+y[1], x[2]+y[2], x[3]+y[3])
Base.:+(x::NTuple{2,Union{Float64,Int}},y::GeometryBasics.Vec{2,Float64}) = GeometryBasics.Vec(x[1]+y[1], x[2]+y[2])
Base.:-(x::NTuple{3,Union{Float64,Int}},y::GeometryBasics.Vec{3,Float64}) = GeometryBasics.Vec(x[1]-y[1], x[2]-y[2], x[3]-y[3])
Base.:-(x::NTuple{2,Union{Float64,Int}},y::GeometryBasics.Vec{2,Float64}) = GeometryBasics.Vec(x[1]-y[1], x[2]-y[2])
# Base.:+(x::MeshCat.Point,y::MeshCat.Point ) = MeshCat.Point(x[1]+y[1], x[2]+y[2], x[3]+y[3])


@inline function _create_props_lists(aprops::Vector{Symbol}, pprops::Vector{Symbol}, mprops::Vector{Symbol}, model::AbstractGridModel)
    for sym in aprops
        if !(sym in model.record.aprops)
            push!(model.record.aprops, sym)
        end
    end

    if length(model.record.aprops)>0
        for agent in model.agents
            unwrap(agent)[:keeps_record_of] = copy(model.record.aprops)
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

    for sym in aprops
        if !(sym in model.record.aprops)
            push!(model.record.aprops, sym)
        end
    end

    if length(model.record.aprops)>0
        for agent in model.agents
            unwrap(agent)[:keeps_record_of] = copy(model.record.aprops)
        end
    end

    for sym in mprops
        if !(sym in model.record.mprops)
            push!(model.record.mprops, sym)
        end
    end
 

    for sym in nprops
        if !(sym in model.record.nprops)
            push!(model.record.nprops, sym)
        end
    end

    for sym in eprops
        if !(sym in model.record.eprops)
            push!(model.record.eprops, sym)
        end
    end

end


@inline function _get_all_agents(model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    return vcat(model.agents, model.parameters._extras._agents_killed)

end

@inline function _get_all_agents(model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType} }) where T<:MType
    return model.agents
end

"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function _permanently_remove_inactive_agents!(model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    for i in length(model.parameters._extras._agents_killed):-1:1
        agent = model.parameters._extras._agents_killed[i]
        if agent._extras._newly_killed
            agent._extras._newly_killed = false
            deleteat!(model.agents, findfirst(m->m==agent, model.agents))
        else
            break
        end
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function commit_add_agents!(model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    agents_to_add = model.parameters._extras._agents_added
    for ag in agents_to_add
        push!(model.agents, ag)
    end
    model.parameters._extras._agents_added = eltype(model.agents)[] 
end

"""
$(TYPEDSIGNATURES)
"""
function _init_model_record!(model::Union{AbstractGridModel, AbstractGraphModel})
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
@inline function _update_model_record!(model::Union{AbstractGridModel, AbstractGraphModel})
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
@inline function _manage_default_data!(agent::AbstractPropDict, model::AbstractGridModel{MortalType})
    push!(model.parameters._extras._agents_added, agent)
    agent._extras._id = getfield(model,:max_id)[]+1
    agent._extras._active = true
    agent._extras._birth_time = model.tick
    agent._extras._death_time = Inf
    if model.parameters._extras._random_positions && !haskey(agent, :pos)                    
        agent.pos = _random_vector(model.size)
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
@inline function _recalculate_position!(agent::AbstractPropDict, size, periodic)
    if haskey(agent, :pos) && periodic
        agent.pos = mod1.(agent.pos, size)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _create_agent_record!(agent::AbstractPropDict, model::Union{AbstractGridModel, AbstractGraphModel})
    if length(model.record.aprops)>0
        unwrap(agent)[:keeps_record_of] = model.record.aprops
    end

    if length(agent.keeps_record_of)==0  # if agents keep_record_of is empty then record everything
        keeps_record_of = Symbol[]
        for key in keys(agent)
            if !(key == :_extras) && !(key==:keeps_record_of)
                push!(keeps_record_of, key)
            end
        end
        unwrap(agent)[:keeps_record_of] = keeps_record_of
    end

end


"""
$(TYPEDSIGNATURES)
"""
@inline function _init_agent_record!(agent::AbstractPropDict)
    agent_dict = unwrap(agent)
    agent_data = unwrap_data(agent)
    for key in agent.keeps_record_of
        agent_data[key] = [agent_dict[key]]
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _update_agent_record!(agent::AbstractPropDict)
    agent_dict = unwrap(agent)
    agent_data = unwrap_data(agent)
    for key in agent.keeps_record_of
        push!(agent_data[key], agent_dict[key])
    end
end


"""
$(TYPEDSIGNATURES)
"""
function _init_agents!(model::AbstractGridModel{MortalType})
    _permanently_remove_inactive_agents!(model)
    commit_add_agents!(model)
    empty!(model.parameters._extras._agents_killed)
    getfield(model,:max_id)[] = length(model.agents)> 0 ? max([ag._extras._id for ag in model.agents]...) : 0
    for agent in model.agents
        agent._extras._birth_time = 1
        _recalculate_position!(agent, model.size, model.periodic)
        _init_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)
"""
function _init_agents!(model::AbstractGridModel{StaticType})
    for agent in model.agents
        _recalculate_position!(agent, model.size, model.periodic)
        _init_agent_record!(agent)
    end
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _kill_agent!(agent::AbstractPropDict, push_to, tick)
        agent._extras._active= false
        agent._extras._death_time = tick
        agent._extras._newly_killed = true
        push!(push_to, agent)
end

"""
$(TYPEDSIGNATURES)

Sets the agent as inactive thus effectively removing from the model. However, the removed agents 
are permanently removed from the list `model.agents` only twice in one step i) After the `agent_step_function` 
has run for all agents and ii) After the `step_rule`.
"""
function kill_agent!(agent::AbstractPropDict, model::AbstractGridModel{MortalType})
    if agent._extras._active
        if haskey(agent, :pos) && (agent._extras._last_grid_loc!=Inf)
            gloc = agent._extras._last_grid_loc
            deleteat!(model.patches[gloc...]._extras._agents, findfirst(m->m==agent._extras._id, model.patches[gloc...]._extras._agents))
        end
        _kill_agent!(agent, model.parameters._extras._agents_killed, model.tick)
    end
end


"""
$(TYPEDSIGNATURES)

Sets the agent as inactive thus effectively removing from the model. However, the removed agents 
are permanently removed from the list `model.agents` only twice in one step i) After the `agent_step_function` 
has run for all agents and ii) After the `step_rule`.
"""
function kill_agent!(agent::AbstractPropDict, model::AbstractGraphModel{T,MortalType}) where T<:MType
    if agent._extras._active
        if haskey(agent, :node)
            x = agent._extras._last_node_loc
            deleteat!(model.graph.nodesprops[x]._extras._agents, findfirst(m->m==agent._extras._id, model.graph.nodesprops[x]._extras._agents))
        end
        _kill_agent!(agent, model.parameters._extras._agents_killed, model.tick)
    end
end


"""
$(TYPEDSIGNATURES)

"""
@inline function _run_sim!(model::Union{AbstractGridModel, AbstractGraphModel }, steps,
    step_rule::Function, do_after::Function) 
 
    for step in 1:steps
        step_rule(model)
        do_after(model)     
    end
end


@inline function loss_of_data_prompt()
    println("Any data collected during previous model run will be lost.")
    print("Want to continue ? y/n :  ")

    flush(stdout)

    u_res = readline()

    return !(u_res in ["y", "Y"])
end




