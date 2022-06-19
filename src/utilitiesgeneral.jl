"""
$(TYPEDSIGNATURES)
"""
function calculate_direction(vel::NTuple{2,T}) where T<:Real #for 2d and graph
    vx, vy = vel
    if (vx ≈ 0.0)
        return 0.0
    end
    if (vx > 0)
        return 1.5*pi+atan(vy/vx)
    end
    if (vx<0) 
        return 0.5*pi+atan(vy/vx)
    end 
end


"""
$(TYPEDSIGNATURES)
"""
function calculate_direction(vel::NTuple{3,T}) where T<:Real
    vx, vy, vz = vel
    ln = sqrt(vx^2+vy^2+vz^2)
    if (ln ≈ 0.0)
        return 0.0
    end
    orientation = vel/ln
    return orientation
end



"""
$(TYPEDSIGNATURES)

Saves the model on disk as jld2 file. 
"""
function save_model(model; model_name::String = _default_modelname, save_as = _default_filename, folder = _default_folder[])
    _save_object_to_disk(model, name = model_name, save_as = save_as, folder = folder)
end 


"""
$(TYPEDSIGNATURES)

Gets the model that was saved before as jld2. 
"""
function open_saved_model(; model_name = _default_modelname, path = joinpath(_default_folder[], _default_filename))
    try
        f = jldopen(path, "r+")
        model = f[model_name]
        close(f)
        return model
    catch e
        print("Error opening file: ", e)
    end
end


@inline function _default_true(agent::AbstractPropDict)
    return true
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::Union{AbstractSpaceModel{MortalType}, AbstractGraphModel{T, MortalType} }, condition::Function = _default_true) where T<:MType
    all_agents = vcat(model.agents, model.parameters._extras._agents_added)
    return all_agents[[(ag._extras._active)&&(condition(ag)) for ag in all_agents]]
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::Union{AbstractSpaceModel{StaticType}, AbstractGraphModel{T, StaticType} }, condition::Function = _default_true) where T<:MType
    if condition == _default_true
        return model.agents
    end
    return model.agents[[condition(ag) for ag in model.agents]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_agents(model::Union{AbstractSpaceModel, AbstractGraphModel }, condition::Function = _default_true)
    if condition == _default_true
        return model.parameters._extras._num_agents # number of active agents
    end
    return length(get_agents(model, condition))
end


"""
$(TYPEDSIGNATURES)

Returns agents id.
"""
function get_id(agent::AbstractPropDict)
    if haskey(agent._extras,:_id)
        return agent._extras._id
    end
end

"""
$(TYPEDSIGNATURES)

Returns true if agent is alive else returns false.
"""
function is_alive(agent::AbstractPropDict)
    return agent._extras._active
end


"""
$(TYPEDSIGNATURES)

Returns true if a node is alive else returns false.
"""
function is_alive(node, model::AbstractGraphModel)
    return model.graph.nodesprops[node]._extras._active
end


"""
$(TYPEDSIGNATURES)

Returns true if a patch is occupied.
"""
function is_occupied(patch, model::AbstractSpaceModel)
    return length(model.patches[patch...]._extras._agents) > 0 
end


"""
$(TYPEDSIGNATURES)

Returns true if a node is occupied. 
"""
function is_occupied(node, model::AbstractGraphModel)
    return length(model.graph.nodesprops[node]._extras._agents) > 0 
end


"""
$(TYPEDSIGNATURES)

Returns node location of the agent.
"""
function get_node_loc(agent::AbstractPropDict, model::AbstractGraphModel)
    return agent.node
end

"""
$(TYPEDSIGNATURES)

Returns an empty node chosen at random. Returns nothing if there is no empty node. 
"""
function random_empty_node(model::AbstractGraphModel)
    verts = get_nodes(model.graph)
    empty_verts = verts[[!(is_occupied(node, model)) for node in verts]]
    n = length(empty_verts)
    if n >0
        m = rand(1:n)
        return empty_verts[m]
    else
        return nothing
    end
end



"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i, model::Union{AbstractSpaceModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    m = model.parameters._extras._len_model_agents

    if i<=m  
        @inbounds for j in i:-1:1 # will work if the list of model agents has not been shuffled
            ag = model.agents[j]
            if ag._extras._id == i
                return ag
            end
        end
    end

    for ag in model.parameters._extras._agents_added # still assuming that the user will avoid shuffling agents list
        if ag._extras._id == i
            return ag
        end
    end

    @inbounds for j in m:-1:1  # check in model.agents list beginning from the end as the initial part has been checked above
        ag = model.agents[j]
        if ag._extras._id == i 
            return ag
        end
    end

    for ag in model.parameters._extras._agents_killed # finally check in the list of killed agents
        if ag._extras._id == i
            return ag
        end
    end

    return missing
    
end

"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i, model::Union{AbstractSpaceModel{StaticType}, AbstractGraphModel{T, StaticType} }) where T<:MType
    if model.agents[i]._extras._id == i  # will work if agents list has not been shuffled
        @inbounds return model.agents[i]
    end

    for ag in model.agents
        if ag._extras._id == i 
            return ag
        end
    end

    return missing
end


"""
$(TYPEDSIGNATURES)

Returns list of agents at a given patch.
"""
function agents_at(patch, model::AbstractSpaceModel)
    lst = model.patches[patch...]._extras._agents
    agent_lst = eltype(model.agents)[]
    for l in lst
        push!(agent_lst, agent_with_id(l, model))
    end
    return agent_lst
end


"""
$(TYPEDSIGNATURES)

Returns list of agents at a given node. 
"""
function agents_at(node, model::AbstractGraphModel)
    lst = model.graph.nodesprops[node]._extras._agents
    agent_lst = eltype(model.agents)[]

    if !model.graph.nodesprops[node]._extras._active
        return agent_lst
    end

    for l in lst
        push!(agent_lst, agent_with_id(l, model))
    end
    return agent_lst
end


"""
$(TYPEDSIGNATURES)

Returns number of agents at a given patch.
"""
function num_agents_at(patch, model::AbstractSpaceModel)
    return length(agents_at(patch, model))
end


"""
$(TYPEDSIGNATURES)

Returns number of agents at a given node. 
"""
function num_agents_at(node, model::AbstractGraphModel)
    return length(agents_at(node, model))
end


"""
$(TYPEDSIGNATURES)

Returns value of given property of a patch. 
"""
function get_patchprop(key, patch, model::AbstractSpaceModel)
    return unwrap(model.patches[patch...])[key]
end


"""
$(TYPEDSIGNATURES)

Sets properties of the patch given as keyword arguments. 
"""
function set_patchprops!(patch, model::AbstractSpaceModel; kwargs...)
    dict = Dict{Symbol, Any}(kwargs...)
    patch_dict = unwrap(model.patches[patch...])
    patch_data = unwrap_data(model.patches[patch...])
    for (key, val) in dict
        patch_dict[key] = val
        if !haskey(patch_data, key)
            patch_data[key] = typeof(val)[]
        end
    end
end
