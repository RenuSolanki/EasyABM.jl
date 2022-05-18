
@inline function _default_true(agent::AbstractPropDict)
    return true
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType} }, condition::Function = _default_true) where T<:MType
    return model.agents[[(ag._extras._active)&&(condition(ag)) for ag in model.agents]]
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType} }, condition::Function = _default_true) where T<:MType
    return model.agents[[condition(ag) for ag in model.agents]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_agents(model::Union{AbstractGridModel, AbstractGraphModel }, condition::Function = _default_true)
    return length(get_agents(model, condition))
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_nodes(graph::AbstractPropGraph{MortalType}, condition::Function = _default_true)
    verts = vertices(graph)
    return verts[[graph.nodesprops[vt]._extras._active && (condition(graph.nodesprops[vt])) for vt in verts]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_nodes(graph::AbstractPropGraph{StaticType}, condition::Function = _default_true)
    verts = vertices(graph)
    return verts[[condition(graph.nodesprops[vt]) for vt in verts]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_nodes(graph::AbstractPropGraph, condition::Function = _default_true)
    return length(get_nodes(graph, condition))
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_edges(graph::AbstractPropGraph{MortalType}, condition::Function = _default_true)
    edges = graph.edges
    return edges[[graph.edgesprops[ed]._extras._active && condition(graph.edgesprops[ed]) for ed in edges]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_edges(graph::AbstractPropGraph{StaticType}, condition::Function = _default_true)
    edges = graph.edges
    return edges[[condition(graph.edgesprops[ed]) for ed in edges]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_edges(graph::AbstractPropGraph, condition::Function = _default_true)
    return length(get_edges(graph, condition))
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

Returns true if a patch is occupied.
"""
function is_occupied(patch, model::AbstractGridModel)
    return length(model.patches[patch]._extras._agents) > 0 
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

Returns grid location of the agent.
"""
function get_grid_loc(agent::AbstractPropDict, model::AbstractGridModel)
    return agent._extras._last_grid_loc
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

Returns an empty node chosen at random. Returns missing if there is no empty node. 
"""
function random_empty_node(model::AbstractGraphModel)
    verts = get_nodes(model.graph)
    empty_verts = verts[[!(is_occupied(node, model)) for node in verts]]
    n = length(verts)
    if n >0
        m = rand(1:n)
        return empty_verts[m]
    else
        return missing
    end
end



"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i, model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType} }) where T<:MType
    ids_agents_added = [ag._extras._id for ag in model.parameters._extras._agents_added]
    if i in ids_agents_added
        index = findfirst(x->x==i, ids_agents_added)
        return model.parameters._extras._agents_added[index]
    end
    m = length(model.agents)
    if i<=m 
        for j in i:-1:1
            ag = model.agents[j]
            if ag._extras._id == i
                return ag
            end
        end

    else
        for j in m:-1:1
            ag = model.agents[j]
            if ag._extras._id ==i
                return ag
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i, model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType} }) where T<:MType
    m = model.max_id[]
    if i<=m 
        for j in i:-1:1
            ag = model.agents[j]
            if ag._extras._id == i
                return ag
            end
        end

    else
        for j in m:-1:1
            ag = model.agents[j]
            if ag._extras._id ==i
                return ag
            end
        end
    end
end


"""
$(TYPEDSIGNATURES)

Returns list of agents at a given patch.
"""
function agents_at(patch, model::AbstractGridModel)
    lst = model.patches[patch]._extras._agents
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
function num_agents_at(patch, model::AbstractGridModel)
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
function get_patchprop(key, patch, model::AbstractGridModel)
    return unwrap(model.patches[patch])[key]
end


"""
$(TYPEDSIGNATURES)

Sets properties of the patch given as keyword arguments. 
"""
function set_patchprops!(patch, model::AbstractGridModel; kwargs...)
    dict = Dict{Symbol, Any}(kwargs...)
    patch_dict = unwrap(model.patches[patch])
    patch_data = unwrap_data(model.patches[patch])
    for (key, val) in dict
        patch_dict[key] = val
        if !haskey(patch_data, key)
            patch_data[key] = [val]
        elseif key in model.record.pprops
            push!(patch_data[key], val)
        end
    end
end

