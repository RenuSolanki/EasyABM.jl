
"""
$(TYPEDSIGNATURES)

Returns nodes neighboring given node.
"""
function neighbor_nodes(node::Int, model::GraphModel)
    return all_neighbors(model.graph, node)
end


"""
$(TYPEDSIGNATURES)

Returns nodes neighboring node of the given agent.
"""
function neighbor_nodes(agent::AgentDictGr, model::GraphModel)

    return all_neighbors(model.graph, agent.node)  
end


"""
$(TYPEDSIGNATURES)

Returns nodes of incoming edges at given node. 
"""
function in_neighbor_nodes(node::Int, model::GraphModel)
    return in_neighbors(model.graph, node)
end


"""
$(TYPEDSIGNATURES)

Returns nodes of incoming edges at given agent's node.
"""
function in_neighbor_nodes(agent::AgentDictGr, model::GraphModel)
    return  in_neighbors(model.graph, agent.node)
end


"""
$(TYPEDSIGNATURES)

Returns nodes of outgoing edges at given node.
"""
function out_neighbor_nodes(node::Int, model::GraphModel)

    return out_neighbors(model.graph, node)

end

"""
$(TYPEDSIGNATURES)

Returns nodes of outgoing edges at given agent's node.
"""
function out_neighbor_nodes(agent::AgentDictGr, model::GraphModel)
    return out_neighbors(model.graph, agent.node)
end

####################
####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _agents_at_nodes(nbr_nodes, model::GraphModel)
    neighbors_list = Vector{AgentDictGr{Symbol, Any}}()
    for node in nbr_nodes
        ids = model.graph.nodesprops[node]._extras._agents # all these are active for inactive ones are removed
        for id in ids
            ag = agent_with_id(id, model)
            push!(neighbors_list, ag)
        end
    end
    return neighbors_list
end

@inline function _agents_node_mates(agent, model)

    ag_node = agent.node
    agents_ids = deepcopy(model.graph.nodesprops[ag_node]._extras._agents)
    deleteat!(agents_ids , findfirst(m->m==agent._extras._id, agents_ids ))
    agents_ag_node = Vector{AgentDictGr{Symbol, Any}}()
    for id in agents_ids
        ag = agent_with_id(id, model)
        push!(agents_ag_node, ag)
    end

    return agents_ag_node

end



"""
$(TYPEDSIGNATURES)

Returns agents on neighboring nodes of given agent.
"""
function neighbors(agent::AgentDictGr, model::GraphModelDynAgNum)
    if !(agent._extras._active)
        return Vector{AgentDictGr{Symbol, Any}}()
    end
    nbr_nodes = neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    agents_ag_node = _agents_node_mates(agent, model)
    

    return vcat(neighbors_list, agents_ag_node)

end


"""
$(TYPEDSIGNATURES)

Returns agents on neighboring nodes of given agent.
"""
function neighbors(agent::AgentDictGr, model::GraphModelFixAgNum)
    nbr_nodes = neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    agents_ag_node = _agents_node_mates(agent, model)
    

    return vcat(neighbors_list, agents_ag_node)

end

####################
####################

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring outgoing nodes of given agent.
"""
function out_neighbors(agent::AgentDictGr, model::GraphModelDynAgNum)
    if !(agent._extras._active)
        return Vector{AgentDictGr{Symbol, Any}}()
    end
    nbr_nodes = out_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    agents_ag_node = _agents_node_mates(agent, model)
    

    return vcat(neighbors_list, agents_ag_node)

end

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring outgoing nodes of given agent.
"""
function out_neighbors(agent::AgentDictGr, model::GraphModelFixAgNum)
    nbr_nodes = out_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    agents_ag_node = _agents_node_mates(agent, model)
    

    return vcat(neighbors_list, agents_ag_node)

end


####################
####################

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring incoming nodes of given agent.
"""
function in_neighbors(agent::AgentDictGr, model::GraphModelDynAgNum)
    if !(agent._extras._active)
        return Vector{AgentDictGr{Symbol, Any}}()
    end
    nbr_nodes = in_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    agents_ag_node = _agents_node_mates(agent, model)
    

    return vcat(neighbors_list, agents_ag_node)

end

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring incoming nodes of given agent.
"""
function in_neighbors(agent::AgentDictGr, model::GraphModelFixAgNum)
    nbr_nodes = in_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    agents_ag_node = _agents_node_mates(agent, model)
    

    return vcat(neighbors_list, agents_ag_node)

end


"""
$(TYPEDSIGNATURES)

Returns the value for given property name for a node.
"""
function get_nodeprop(key::Symbol, node::Int, model::GraphModel)
    _get_vertexprop(model.graph, node, key)
end

"""
$(TYPEDSIGNATURES)

Returns the value for given property name for an edge.
"""
function get_edgeprop(key::Symbol, i::Int,j::Int, model::GraphModel)
    _get_edgeprop(model.graph, i,j, key)
end

"""
$(TYPEDSIGNATURES)

Returns the value for given property name for an edge.
"""
function get_edgeprop(key::Symbol, edge, model::GraphModel)
    i,j=edge
    _get_edgeprop(model.graph, i,j, key)
end


"""
$(TYPEDSIGNATURES)

Sets properties of given node.
"""
function set_nodeprops!(node::Int, model::GraphModel; kwargs...)
    _set_vertexprops!(model.graph, node; kwargs...)
    dict = Dict{Symbol, Any}(kwargs...)
    node_dict = unwrap(model.graph.nodesprops[node])
    node_data = unwrap_data(model.graph.nodesprops[node])
    for (key, val) in dict
        node_dict[key] = val
        if !haskey(node_data, key)
            node_data[key] = typeof(val)[]
        end
    end
end

"""
$(TYPEDSIGNATURES)

Sets properties of given edge.
"""
function set_edgeprops!(i::Int,j::Int, model::GraphModel; kwargs...)
    i,j=_set_edgeprops!(model.graph, i,j; kwargs...)
    dict = Dict{Symbol, Any}(kwargs...)
    edge_dict = unwrap(model.graph.edgesprops[(i,j)])
    edge_data = unwrap_data(model.graph.edgesprops[(i,j)])
    for (key, val) in dict
        edge_dict[key] = val
        if !haskey(edge_data, key)
            edge_data[key] = typeof(val)[]
        end
    end
end

"""
$(TYPEDSIGNATURES)

Sets properties of given edge.
"""
function set_edgeprops!(edge, model::GraphModel; kwargs...)
    i,j=edge
    set_edgeprops!(i,j, model; kwargs...)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_nodes(model::GraphModel, condition::Function = _default_true) # choose from active nodes
    verts = getfield(model.graph, :_nodes)
    if condition == _default_true
        return verts
    end
    return verts[[condition(model.graph.nodesprops[vt]) for vt in verts]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_nodes(model::GraphModel, condition::Function = _default_true)
    if condition == _default_true
        return model.parameters._extras._num_verts # number of active verts
    end
    return length(get_nodes(model, condition))
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_edges(model::GraphModel, condition::Function = _default_true)
    eds = edges(model.graph)
    if condition == _default_true # for edges may not have properties assigned to them
        return eds
    end
    return eds[[condition(model.graph.edgesprops[ed]) for ed in eds]]
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_edges(model::GraphModel, condition::Function = _default_true)
    if condition == _default_true
        return model.parameters._extras._num_edges # num of active edges
    end
    return length(get_edges(model, condition))
end


"""
$(TYPEDSIGNATURES)
"""
function square_grid(n, k; periodic = false)
    m = n*k
    nodenum(i,j) = (j-1)*k+i
    gr = create_simple_graph(m)
    if n>=2
        _add_edge_f!(gr,nodenum(1,1),nodenum(1,2))
        _add_edge_f!(gr,nodenum(k,1),nodenum(k,2))
        _add_edge_f!(gr,nodenum(1,n),nodenum(1,n-1))
        _add_edge_f!(gr,nodenum(k,n),nodenum(k,n-1))
    end
    if k>=2
        _add_edge_f!(gr,nodenum(1,1),nodenum(2,1))
        _add_edge_f!(gr,nodenum(1,n),nodenum(2,n))
        _add_edge_f!(gr,nodenum(k,1),nodenum(k-1,1))
        _add_edge_f!(gr,nodenum(k,n),nodenum(k-1,n))
    end
    
    
    if k==2
        for j in 2:(n-1)
            _add_edge_f!(gr, nodenum(1,j),nodenum(2,j))
        end
    end

    if n==2
        for i in 2:(k-1)
            _add_edge_f!(gr, nodenum(i,1),nodenum(i,2))
        end
    end

    for i in 1:k
        for j in 1:n
            node = nodenum(i,j)
            gr.nodesprops[node] = PropDataDict()
            gr.nodesprops[node]._extras._pos = ((i-0.5)*gsize/k,(j-0.5)*gsize/n)
            if (i <k)&&(i>1)&&(j<n)&&(j>1)
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j-1))
            elseif ((i==1)||(i==k))&&(j>1)&&(j<n)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i,j-1))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i,j+1))
            elseif ((j==1)||(j==n))&&(i>1)&&(i<k)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i+1,j))
            end
            if i==1 && periodic
                _add_edge_f!(gr, nodenum(1,j), nodenum(k,j))
            end
            if j==1 && periodic
                _add_edge_f!(gr, nodenum(i,1), nodenum(i,n))
            end
        end
    end
    return gr
end


"""
$(TYPEDSIGNATURES)
"""
function hex_grid(n, k)
    n = n%2==0 ? n : n+1 # n must be even
    k = 2k+1 # this k will count number of verts along x axis
    m = n*k
    nodenum(i,j) = (j-1)*k+i
    gr = create_simple_graph(m)
    _add_edge_f!(gr,nodenum(1,1),nodenum(1,2))
    _add_edge_f!(gr,nodenum(1,1),nodenum(2,1))
    _add_edge_f!(gr,nodenum(1,n),nodenum(1,n-1))
    _add_edge_f!(gr,nodenum(1,n),nodenum(2,n))
    _add_edge_f!(gr,nodenum(k,1),nodenum(k,2))
    _add_edge_f!(gr,nodenum(k,1),nodenum(k-1,1))
    _add_edge_f!(gr,nodenum(k,n),nodenum(k-1,n))
    _add_edge_f!(gr,nodenum(k,n),nodenum(k,n-1))

    if n==2
        for i in 2:(k-1)
            if i%2==1
                _add_edge_f!(gr, nodenum(i,1),nodenum(i,2))
            end
        end
    end

    for i in 1:k
        for j in 1:n
            if (i <k)&&(i>1)&&(j<n)&&(j>1)
                if i%2 == j%2
                    _add_edge_f!(gr, nodenum(i,j),nodenum(i,j+1))
                end
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j))
            elseif ((i==1)||(i==k))&&(j>1)&&(j<n)
                if j%2 == 1
                _add_edge_f!(gr, nodenum(i,j), nodenum(i,j+1))
                end
            elseif ((j==1)||(j==n))&&(i>1)&&(i<k)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i+1,j))
                if (i%2 == 1)&&(j==1)
                    _add_edge_f!(gr, nodenum(i,1),nodenum(i,2))
                end
            end
            node = nodenum(i,j)
            gr.nodesprops[node] = PropDataDict()
            gr.nodesprops[node]._extras._pos = ((i-0.5)*gsize/k,(j-0.5)*gsize/n)
            if nodenum(i,j+1) in gr.structure[nodenum(i,j)] || ((j==n)&&(i%2==0))
                gr.nodesprops[node]._extras._pos = ((i-0.5)*gsize/k,(j-0.5)*gsize/n + (gsize/n)*0.17)
            elseif (nodenum(i,j-1) in gr.structure[nodenum(i,j)]) || ((j==1)&&(i%2==0))
                gr.nodesprops[node]._extras._pos = ((i-0.5)*gsize/k,(j-0.5)*gsize/n - (gsize/n)*0.17)
            else
                gr.nodesprops[node]._extras._pos = ((i-0.5)*gsize/k,(j-0.5)*gsize/n)
            end
        end
    end
    return gr
end


"""
$(TYPEDSIGNATURES)
"""
function triangular_grid(n, k)
    m = n*k
    nodenum(i,j) = (j-1)*k+i
    gr = create_simple_graph(m)
    if n>=2
        _add_edge_f!(gr,nodenum(1,1),nodenum(1,2))
        _add_edge_f!(gr,nodenum(k,1),nodenum(k,2))
        _add_edge_f!(gr,nodenum(1,n),nodenum(1,n-1))
        _add_edge_f!(gr,nodenum(k,n),nodenum(k,n-1))
    end
    if k>=2
        _add_edge_f!(gr,nodenum(1,1),nodenum(2,1))
        _add_edge_f!(gr,nodenum(1,n),nodenum(2,n))
        _add_edge_f!(gr,nodenum(k,1),nodenum(k-1,1))
        _add_edge_f!(gr,nodenum(k,n),nodenum(k-1,n))
    end
    if (k==2)&&(n>=2)
        for j in 2:(n-1)
            _add_edge_f!(gr, nodenum(1,j),nodenum(2,j))
        end
        _add_edge_f!(gr,nodenum(1,1),nodenum(2,2))
    end

    if (n==2)&&(k>=2)
        for i in 2:(k-1)
            _add_edge_f!(gr, nodenum(i,1),nodenum(i,2))
        end
        _add_edge_f!(gr,nodenum(1,1),nodenum(2,2))
    end

    for i in 1:k
        for j in 1:n
            node = nodenum(i,j)
            gr.nodesprops[node] = PropDataDict()
            gr.nodesprops[node]._extras._pos = ((i-0.5)*gsize/k,(j-0.5)*gsize/n)
            if (i <k)&&(i>1)&&(j<n)&&(j>1)
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j-1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j-1))
            elseif ((i==1)||(i==k))&&(j>1)&&(j<n)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i,j-1))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i,j+1))
                if (i==1)&&(k>=2)
                    _add_edge_f!(gr, nodenum(1,j), nodenum(2,j+1))
                end
            elseif ((j==1)||(j==n))&&(i>1)&&(i<k)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i+1,j))
                if (j==1)&&(n>=2)
                    _add_edge_f!(gr, nodenum(i,j), nodenum(i+1,j+1))
                end
            end
        end
    end
    return gr
end


"""
$(TYPEDSIGNATURES)
"""
function double_triangular_grid(n, k)
    m = n*k
    nodenum(i,j) = (j-1)*k+i
    gr = create_simple_graph(m)
    if n>=2
        _add_edge_f!(gr,nodenum(1,1),nodenum(1,2))
        _add_edge_f!(gr,nodenum(k,1),nodenum(k,2))
        _add_edge_f!(gr,nodenum(1,n),nodenum(1,n-1))
        _add_edge_f!(gr,nodenum(k,n),nodenum(k,n-1))
    end
    if k>=2
        _add_edge_f!(gr,nodenum(1,1),nodenum(2,1))
        _add_edge_f!(gr,nodenum(1,n),nodenum(2,n))
        _add_edge_f!(gr,nodenum(k,1),nodenum(k-1,1))
        _add_edge_f!(gr,nodenum(k,n),nodenum(k-1,n))
    end
    if (k==2)&&(n>=2)
        for j in 2:(n-1)
            _add_edge_f!(gr, nodenum(1,j),nodenum(2,j))
        end
        _add_edge_f!(gr,nodenum(1,1),nodenum(2,2))
        _add_edge_f!(gr,nodenum(2,1),nodenum(1,2))
    end

    if (n==2)&&(k>=2)
        for i in 2:(k-1)
            _add_edge_f!(gr, nodenum(i,1),nodenum(i,2))
        end
        _add_edge_f!(gr,nodenum(1,1),nodenum(2,2))
        _add_edge_f!(gr,nodenum(2,1),nodenum(1,2))
    end

    for i in 1:k
        for j in 1:n
            node = nodenum(i,j)
            gr.nodesprops[node] = PropDataDict()
            gr.nodesprops[node]._extras._pos = ((i-0.5)*gsize/k,(j-0.5)*gsize/n)
            if (i <k)&&(i>1)&&(j<n)&&(j>1)
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j-1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j-1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j-1))
            elseif ((i==1)||(i==k))&&(j>1)&&(j<n)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i,j-1))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i,j+1))
                if (i==1)&&(k>=2)
                    _add_edge_f!(gr, nodenum(1,j), nodenum(2,j+1))
                    _add_edge_f!(gr, nodenum(1,j+1), nodenum(2,j))
                end
            elseif ((j==1)||(j==n))&&(i>1)&&(i<k)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i+1,j))
                if (j==1)&&(n>=2)
                    _add_edge_f!(gr, nodenum(i,j), nodenum(i+1,j+1))
                    _add_edge_f!(gr, nodenum(i,j), nodenum(i-1,j+1))
                end
            end
        end
    end
    return gr
end


