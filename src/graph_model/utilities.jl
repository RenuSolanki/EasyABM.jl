
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
function neighbor_nodes(agent::GraphAgent, model::GraphModel)

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
function in_neighbor_nodes(agent::GraphAgent, model::GraphModel)
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
function out_neighbor_nodes(agent::GraphAgent, model::GraphModel)
    return out_neighbors(model.graph, agent.node)
end

####################
####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _agents_at_nodes(nbr_nodes, model::GraphModel)
    return (agent_with_id(id, model) for node in nbr_nodes for id in model.graph.nodesprops[node].agents)
end

@inline function _agents_node_mates(agent, model)
    i = getfield(agent, :id)
    ids = model.graph.nodesprops[agent.node].agents
    return (agent_with_id(l, model) for l in ids if l!=i)

end

@inline function _append_agents_node_mates!(agent, model, neighbors_list::Vector{GraphAgent{Symbol, Any, S}}) where S<:MType
    i = getfield(agent, :id)
    for l in model.graph.nodesprops[agent.node].agents
        if l !=i
            ag = agent_with_id(l, model)::GraphAgent
            push!(neighbors_list, ag)
        end
    end
end



"""
$(TYPEDSIGNATURES)

Returns agents on neighboring nodes of given agent.
"""
function neighbors(agent::GraphAgent, model::GraphModelDynAgNum)
    if !(agent._extras._active::Bool)
        return (j for j in 1:0)
    end
    nbr_nodes = neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    node_mates = _agents_node_mates(agent, model)
    allmates = [neighbors_list, node_mates]
    return (j for i in 1:2 for j in allmates[i]) 

end


"""
$(TYPEDSIGNATURES)

Returns agents on neighboring nodes of given agent.
"""
function neighbors(agent::GraphAgent, model::GraphModelFixAgNum)
    nbr_nodes = neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    node_mates = _agents_node_mates(agent, model)
    allmates = [neighbors_list, node_mates]
    return (j for i in 1:2 for j in allmates[i]) 
end

####################
####################

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring outgoing nodes of given agent.
"""
function out_neighbors(agent::GraphAgent, model::GraphModelDynAgNum)
    if !(agent._extras._active::Bool)
        return (j for j in 1:0)
    end
    nbr_nodes = out_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    node_mates = _agents_node_mates(agent, model)
    allmates = [neighbors_list, node_mates]
    return (j for i in 1:2 for j in allmates[i]) 

end

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring outgoing nodes of given agent.
"""
function out_neighbors(agent::GraphAgent, model::GraphModelFixAgNum)
    nbr_nodes = out_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    node_mates = _agents_node_mates(agent, model)
    allmates = [neighbors_list, node_mates]
    return (j for i in 1:2 for j in allmates[i]) 
end


####################
####################

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring incoming nodes of given agent.
"""
function in_neighbors(agent::GraphAgent, model::GraphModelDynAgNum)
    if !(agent._extras._active::Bool)
        return (j for j in 1:0)
    end
    nbr_nodes = in_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    node_mates = _agents_node_mates(agent, model)
    allmates = [neighbors_list, node_mates]
    return (j for i in 1:2 for j in allmates[i]) 

end

"""
$(TYPEDSIGNATURES)

Returns agents on neighboring incoming nodes of given agent.
"""
function in_neighbors(agent::GraphAgent, model::GraphModelFixAgNum)
    nbr_nodes = in_neighbor_nodes(agent, model)
    neighbors_list = _agents_at_nodes(nbr_nodes, model)
    node_mates = _agents_node_mates(agent, model)
    allmates = [neighbors_list, node_mates]
    return (j for i in 1:2 for j in allmates[i]) 
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
@inline function get_nodes(model::GraphModel, condition::Function ) # choose from active nodes
    verts = getfield(model.graph, :_nodes)
    return Iterators.filter(vt->condition(model.graph.nodesprops[vt]),verts)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_nodes(model::GraphModel) # choose from active nodes
    return (vt for vt in getfield(model.graph, :_nodes))
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_nodes(model::GraphModel, condition::Function )
    return count(x->true,get_nodes(model, condition))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function num_nodes(model::GraphModel)
    return model.parameters._extras._num_verts::Int # number of active verts
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_edges(model::GraphModel, condition::Function)
    eds = edges(model.graph)
    return Iterators.filter(ed->condition(model.graph.edgesprops[ed]), eds) 
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_edges(model::GraphModel)
    return edges(model.graph)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_edges(model::GraphModel, condition::Function)
    return count(x->true,get_edges(model, condition))
end


"""
$(TYPEDSIGNATURES)
"""
@inline function num_edges(model::GraphModel)
    return model.parameters._extras._num_edges::Int # num of active edges
end

"""
$(TYPEDSIGNATURES)

Returns node location of the agent.
"""
function get_node_loc(agent::GraphAgent)
    return agent.node
end


"""
$(TYPEDSIGNATURES)

Returns list of agents at a given node. 
"""
function agents_at(node, model::GraphModel{Mortal, T}) where T<:MType #modifiable graph
    lst = model.graph.nodesprops[node].agents

    if !(model.graph.nodesprops[node]._extras._active::Bool)
        return (ag for ag in GraphAgent{Symbol, Any}[])
    end
    return (agent_with_id(l, model) for l in lst)
end


"""
$(TYPEDSIGNATURES)

Returns list of agents at a given node. 
"""
function agents_at(node, model::GraphModel{Static, T}) where T<:MType #unmodifiable graph
    lst = model.graph.nodesprops[node].agents
 
    return (agent_with_id(l, model) for l in lst)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::GraphModel{T, Mortal}, condition::Function) where {T<:MType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return Iterators.filter(ag-> (ag._extras._active::Bool)&&(condition(ag)), all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::GraphModel{T, Mortal}) where {T<:MType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return Iterators.filter(ag-> ag._extras._active::Bool, all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::GraphModel{T, Static}, condition::Function) where {T<:MType}
    return Iterators.filter(ag-> condition(ag), model.agents)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::GraphModel{T, Static}) where {T<:MType}
    return (ag for ag in model.agents)
end


"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i::Int, model::GraphModel{T, Mortal}) where T<:MType
    m = model.parameters._extras._len_model_agents::Int

    if i<=m  
        for j in i:-1:1 # will work if the list of model agents has not been shuffled
            ag = model.agents[j]
            if getfield(ag, :id) == i
                return ag
            end
        end
    end

    for ag in model.agents_added # still assuming that the user will avoid shuffling agents list
        if getfield(ag, :id) == i
            return ag
        end
    end

    for j in m:-1:1  # check in model.agents list beginning from the end as the initial part has been checked above
        ag = model.agents[j]
        if getfield(ag, :id) == i 
            return ag
        end
    end

    for ag in model.agents_killed # finally check in the list of killed agents
        if getfield(ag, :id) == i
            return ag
        end
    end

    return nothing
    
end

"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i::Int, model::GraphModel{T, Static}) where T<:MType
    if getfield(model.agents[i],:id) == i  # will work if agents list has not been shuffled
        return model.agents[i]
    end

    for ag in model.agents
        if getfield(ag, :id) == i 
            return ag
        end
    end

    return nothing
end




"""
$(TYPEDSIGNATURES)
"""
function square_grid_graph(n, k; periodic = false, dynamic=false)
    m = n*k
    nodenum(i,j) = (j-1)*k+i
    if dynamic
        gr = dynamic_simple_graph(m)
    else
        gr = static_simple_graph(m)
    end
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
            gr.nodesprops[node] = ContainerDataDict()
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
    for ed in edges(gr)
        gr.edgesprops[ed] = PropDataDict()
    end
    return gr
end


"""
$(TYPEDSIGNATURES)
"""
function hex_grid_graph(n, k; dynamic=false)
    n = n%2==0 ? n : n+1 # n must be even
    k = 2k+1 # this k will count number of verts along x axis
    m = n*k
    nodenum(i,j) = (j-1)*k+i
    
    if dynamic
        gr = dynamic_simple_graph(m)
    else
        gr = static_simple_graph(m)
    end

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
            gr.nodesprops[node] = ContainerDataDict()
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
    for ed in edges(gr)
        gr.edgesprops[ed] = PropDataDict()
    end
    return gr
end


"""
$(TYPEDSIGNATURES)
"""
function triangular_grid_graph(n, k; dynamic=false)
    m = n*k
    nodenum(i,j) = (j-1)*k+i
    
    diag_full = sqrt(2)*gsize
    diag_part = diag_full*0.05
    in_pos = (diag_part*cos(pi*45/180), diag_part*sin(pi*45/180))
    y_vec = ((diag_full-2*diag_part)*0.5/((n-1)*cos(pi/6))) .* (cos(pi*75/180), sin(pi*75/180))
    x_vec = ((diag_full-2*diag_part)*0.5/((k-1)*cos(pi/6))) .* (cos(pi*15/180), sin(pi*15/180))
 
    if dynamic
        gr = dynamic_simple_graph(m)
    else
        gr = static_simple_graph(m)
    end

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
        _add_edge_f!(gr,nodenum(2,1),nodenum(1,2))
    end

    if (n==2)&&(k>=2)
        for i in 2:(k-1)
            _add_edge_f!(gr, nodenum(i,1),nodenum(i,2))
        end
        _add_edge_f!(gr,nodenum(2,1),nodenum(1,2))
    end
    
    if (k>=2)&&(n>=2)
        _add_edge_f!(gr,nodenum(k,n-1),nodenum(k-1,n))
    end

    for i in 1:k
        for j in 1:n
            node = nodenum(i,j)
            gr.nodesprops[node] = ContainerDataDict()
            gr.nodesprops[node]._extras._pos = in_pos .+ ((i-1) .* x_vec) .+ ((j-1) .* y_vec) #((i-0.5)*gsize/k,(j-0.5)*gsize/n)
            if (i <k)&&(i>1)&&(j<n)&&(j>1)
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i,j-1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i-1,j+1))
                _add_edge_f!(gr, nodenum(i,j),nodenum(i+1,j-1))
            elseif ((i==1)||(i==k))&&(j>1)&&(j<n)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i,j-1))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i,j+1))
                if (i==1)&&(k>=2)
                    _add_edge_f!(gr, nodenum(1,j+1), nodenum(2,j))
                end
            elseif ((j==1)||(j==n))&&(i>1)&&(i<k)
                _add_edge_f!(gr,nodenum(i,j),nodenum(i-1,j))
                _add_edge_f!(gr, nodenum(i,j), nodenum(i+1,j))
                if (j==1)&&(n>=2)
                    _add_edge_f!(gr, nodenum(i,j), nodenum(i-1,j+1))
                end
            end
        end
    end
    for ed in edges(gr)
        gr.edgesprops[ed] = PropDataDict()
    end
    return gr
end


"""
$(TYPEDSIGNATURES)
"""
function double_triangular_grid_graph(n, k; dynamic=false)
    m = n*k
    nodenum(i,j) = (j-1)*k+i

    if dynamic
        gr = dynamic_simple_graph(m)
    else
        gr = static_simple_graph(m)
    end

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
    if (k>=2)&&(n>=2)
        _add_edge_f!(gr,nodenum(k,n-1),nodenum(k-1,n))
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
            gr.nodesprops[node] = ContainerDataDict()
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
    for ed in edges(gr)
        gr.edgesprops[ed] = PropDataDict()
    end
    return gr
end



"""
$(TYPEDSIGNATURES)
"""
function graph_from_dict(dict::Dict)
    num_nodes=0
    if haskey(dict, "num_nodes")
        num_nodes = dict["num_nodes"]
    elseif haskey(dict, "edges")
        mx=0
        for ed in dict["edges"]
            mx=max(mx, ed...)
        end
        num_nodes=mx
    end

    is_directed = false
    if haskey(dict, "is_directed")
        is_directed = dict["is_directed"]
    end

    is_dynamic = false
    if haskey(dict, "is_dynamic")
        is_dynamic = dict["is_dynamic"]
    end

    if is_directed && is_dynamic
        gr = dynamic_dir_graph(num_nodes)
    elseif is_directed && !(is_dynamic)
        gr = static_dir_graph(num_nodes)
    elseif !(is_directed) && is_dynamic
        gr = dynamic_simple_graph(num_nodes)
    else
        gr = static_simple_graph(num_nodes)
    end

    edgs = Vector{Tuple{Int64, Int64}}()

    if haskey(dict, "edges")
        edgs = dict["edges"]
    end

    for nd in 1:num_nodes
        gr.nodesprops[nd] = ContainerDataDict()
    end

    if haskey(dict, "positions")
        positions = dict["positions"]
        for nd in 1:num_nodes
            gr.nodesprops[nd].pos = positions[nd]
        end
    end

    if haskey(dict,"colors")
        colors = dict["colors"]
        if length(colors)==0
            colors = Col[]
            for _ in 1:num_nodes
                push!(colors, cl"white")
            end
        end
        if (length(colors)>0)&& (length(colors)< num_nodes)
            extra = num_nodes-length(colors)
            for _ in 1:extra
                push!(colors, cl"white")
            end
        end
        for nd in 1:num_nodes
            gr.nodesprops[nd].color = colors[nd]
        end
    end

    if haskey(dict,"sizes")
        sizes = dict["sizes"]
        if length(sizes)==0
            sizes = Float64[]
            sz = _get_node_size(num_nodes)
            for _ in 1:num_nodes
                push!(sizes, sz)
            end
        end
        if (length(sizes)>0)&& (length(sizes)< num_nodes)
            extra = num_nodes-length(sizes)
            sz = sizes[end]
            for _ in 1:extra
                push!(sizes, sz)
            end
        end
        for nd in 1:num_nodes
            gr.nodesprops[nd].size = sizes[nd]
        end
    end

    for ed in edgs 
        a,b=ed
        _add_edge_f!(gr,a,b)
    end

    for ed in edges(gr)
        gr.edgesprops[ed] = PropDataDict()
    end

    return gr
end

