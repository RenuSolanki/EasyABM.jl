"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
function manage_default_graphics_data!(agent::GraphAgent, graphics)
    if graphics
        if !haskey(agent, :shape)
            agent.shape = :circle
        end

        if !haskey(agent, :color)
            agent.color = :red
        end

        if !haskey(agent, :size)
            agent.size = 4
        end

        if !haskey(agent, :orientation)
            agent.orientation = 0.0
        end

    end
end

"""
$(TYPEDSIGNATURES)
"""
function _create_dead_meta_graph(graph::SimplePropGraph{S}) where S<:MType
    _nodes =Int[]
    _structure = Dict{Int, Vector{Int}}()
    for i in getfield(graph, :_nodes)
        _structure[i] = Int[]
    end

    dead_meta_graph = SimplePropGraph(_nodes, _structure, 
     Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}(),S)
     return dead_meta_graph
end

"""
$(TYPEDSIGNATURES)
"""
function _create_dead_meta_graph(graph::DirPropGraph{S}) where S<:MType
    _nodes =Int[]
    _in_structure = Dict{Int, Vector{Int}}()
    _out_structure = Dict{Int, Vector{Int}}()
    for i in getfield(graph, :_nodes)
        _in_structure[i] = Int[]
        _out_structure[i] = Int[]
    end
    dead_meta_graph = DirPropGraph(_nodes, _in_structure, _out_structure, 
     Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}(),S)
     return dead_meta_graph
end

"""
$(TYPEDSIGNATURES)
"""
function _refill_dead_meta_graph!(dead_graph::SimplePropGraph, graph::SimplePropGraph)
    _structure = dead_graph.structure
    for i in getfield(graph, :_nodes)
        _structure[i] = Int[]
    end
end

"""
$(TYPEDSIGNATURES)
"""
function _refill_dead_meta_graph(dead_graph::DirPropGraph, graph::DirPropGraph)
    _in_structure = dead_graph.in_structure
    _out_structure = dead_graph.out_structure
    for i in getfield(graph, :_nodes)
        _in_structure[i] = Int[]
        _out_structure[i] = Int[]
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _create_a_node!(model::GraphModelDynGrTop) #used only when model.graph is empty
    num = model.parameters._extras._max_node_id::Int+1
    _create_node_structure!(num, model.graph, model)
    madict = ContainerDataDict() 
    madict._extras._active = true
    madict._extras._birth_time = model.tick
    madict._extras._death_time = typemax(Int)
    model.graph.nodesprops[num] = madict
    empty!(model.record.nprops)
    model.parameters._extras._num_verts::Int += 1
    model.parameters._extras._num_all_verts::Int += 1
    model.parameters._extras._max_node_id = num
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _create_a_node!(model::GraphModelFixGrTop) #used only when model.graph is empty
    num = model.parameters._extras._max_node_id::Int+1
    _create_node_structure!(num, model.graph, model)
    madict = ContainerDataDict()
    model.graph.nodesprops[num] = madict
    empty!(model.record.nprops)
    model.parameters._extras._num_verts::Int += 1
    model.parameters._extras._num_all_verts::Int += 1
    model.parameters._extras._max_node_id = num
end




"""
$(TYPEDSIGNATURES)

Adds the agent to the model.
"""
function add_agent!(agent, model::GraphModelDynAgNum)
    if (agent._extras._active::Bool)&&(agent._extras._new::Bool)
        if model.parameters._extras._num_verts::Int == 0
            _create_a_node!(model)
        end
    
        verts = get_nodes(model)
        len_verts = model.parameters._extras._num_verts::Int #number of active verts
        random_positions = model.parameters._extras._random_positions::Bool

        if !(agent.node in verts)
            if random_positions
                default_node = verts[rand(1:len_verts)] # if random_positions is true, we need to assign a pos property
            else
                default_node = verts[1]
            end
            setfield!(agent, :node, default_node)
        end

        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics)

        node = agent.node 

        push!(model.graph.nodesprops[node].agents, getfield(agent, :id))

        setfield!(agent, :model, model)

        _create_agent_record!(agent, model)

        _init_agent_record!(agent)

        getfield(model,:max_id)[] +=1
        model.parameters._extras._num_agents::Int += 1 #active agents
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _create_node_structure!(node, graph::SimplePropGraph, model)
    push!(getfield(graph, :_nodes), node)
    graph.structure[node] = Int[]
    if model.parameters._extras._keep_deads_data::Bool
        dead_graph = model.dead_meta_graph
        dead_graph.structure[node]=Int[]
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _create_node_structure!(node, graph::DirPropGraph, model)
    push!(getfield(graph, :_nodes), node)
    graph.in_structure[node] = Int[]
    graph.out_structure[node] = Int[]
    if model.parameters._extras._keep_deads_data::Bool
        dead_graph = model.dead_meta_graph
        dead_graph.in_structure[node]=Int[]
        dead_graph.out_structure[node]=Int[]
    end
end

"""
$(TYPEDSIGNATURES)

Adds a node with properties specified in `kwargs` to the model's graph.
"""
function add_node!(model::GraphModelDynGrTop; kwargs...)
    node = model.parameters._extras._max_node_id::Int+1
    _create_node_structure!(node, model.graph, model)
    madict = ContainerDataDict(Dict{Symbol, Any}(kwargs))
    madict._extras._active=true
    madict._extras._birth_time = model.tick
    madict._extras._death_time=typemax(Int)
    model.graph.nodesprops[node] = madict
    model.parameters._extras._num_verts::Int +=1
    model.parameters._extras._num_all_verts::Int+=1
    model.parameters._extras._max_node_id::Int = node
    if model.graphics && !haskey(model.graph.nodesprops[node], :pos) && !haskey(model.graph.nodesprops[node]._extras::PropDict, :_pos)
        model.graph.nodesprops[node]._extras._pos = (rand()*gsize, rand()*gsize)
    end
    if length(model.record.nprops)>0
        node_dict = unwrap(model.graph.nodesprops[node])
        node_data = unwrap_data(model.graph.nodesprops[node])
        for key in model.record.nprops
            node_data[key] = [node_dict[key]]
        end
    end
    return node
end

"""
$(TYPEDSIGNATURES)

Adds n nodes with properties specified in `kwargs` to the model's graph.
"""
function add_nodes!(n, model::GraphModelDynGrTop; kwargs...)
    for i in 1:n
        add_node!(model; kwargs...)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function add_node!(model::GraphModelFixGrTop; kwargs...)
    _static_graph_error()
end

"""
$(TYPEDSIGNATURES)
"""
function add_nodes!(n, model::GraphModelFixGrTop; kwargs...)
    _static_graph_error()
end

"""
$(TYPEDSIGNATURES)

Removes the graph and all of related data completely. 
"""
function flush_graph!(model::GraphModelDynGrTop) 
    empty!(model.graph)
    empty!(model.dead_meta_graph)
    model.parameters._extras._num_verts::Int =0
    model.parameters._extras._num_all_verts::Int=0
    model.parameters._extras._max_node_id::Int = 0
end

"""
$(TYPEDSIGNATURES)
"""
function flush_graph!(model::GraphModelFixGrTop)
    _static_graph_error()
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _update_edge_structure!(i, j, graph::SimplePropGraph)
    push!(graph.structure[i],j)
    push!(graph.structure[j],i)
end 

"""
$(TYPEDSIGNATURES)
"""
@inline function _update_edge_structure!(i, j, graph::DirPropGraph)
    push!(graph.out_structure[i],j)
    push!(graph.in_structure[j], i)
end 

"""
$(TYPEDSIGNATURES)
"""
@inline function _add_edge_condition(nodes,i,j,graph::SimplePropGraph)
    i, j = i>j ? (j,i) : (i,j)
    condition = (i in nodes)&&(j in nodes)&&(i!=j)&&(!(j in graph.structure[i]))
    return i,j,condition
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _add_edge_condition(nodes,i,j,graph::DirPropGraph)
    condition = (i in nodes)&&(j in nodes)&&(i!=j)&&(!(j in graph.out_structure[i]))
    return i, j, condition
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _checkout_dead_graph(i,j,graph::SimplePropGraph{Mortal})
    condition = (j in graph.structure[i])
    if condition 
        deleteat!(graph.structure[i], findfirst(x-> x==j, graph.structure[i]))
        deleteat!(graph.structure[j], findfirst(x-> x==i, graph.structure[j]))
        delete!(graph.edgesprops, (i,j))
    end
    return condition   
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _checkout_dead_graph(i,j,graph::DirPropGraph{Mortal})
    condition = (j in graph.out_structure[i])
    if condition 
        deleteat!(graph.out_structure[i], findfirst(x-> x==j, graph.out_structure[i]))
        deleteat!(graph.in_structure[j], findfirst(x-> x==i, graph.in_structure[j]))
        delete!(graph.edgesprops, (i,j))
    end
    return condition  
end



"""
$(TYPEDSIGNATURES)

Adds an edge with properties `kwargs` to model graph. 
"""
function create_edge!(i, j, model::GraphModelDynGrTop; kwargs...)
    nodes = getfield(model.graph, :_nodes)
    i,j,condition = _add_edge_condition(nodes,i,j,model.graph)
    if condition
        _update_edge_structure!(i, j, model.graph)
        madict = PropDataDict(Dict{Symbol, Any}(kwargs))
        con = _checkout_dead_graph(i,j, model.dead_meta_graph)
        if con
            madict = model.graph.edgesprops[(i,j)]
            push!(madict._extras._bd_times::Vector{Tuple{Int, Int}}, (model.tick, typemax(Int)))
        else
            madict._extras._bd_times = [(model.tick, typemax(Int))]
        end
        madict._extras._active=true
        model.parameters._extras._num_edges::Int +=1
        model.graph.edgesprops[(i,j)] = madict
        if length(model.record.eprops)>0
            edge_dict = unwrap(model.graph.edgesprops[(i,j)])
            edge_data = unwrap_data(model.graph.edgesprops[(i,j)])
            for key in model.record.eprops
                edge_data[key] = [edge_dict[key]]
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)

Adds an edge with properties `kwargs` to model graph. 
"""
function create_edge!(edge, model::GraphModelDynGrTop; kwargs...)
    i,j = edge
    create_edge!(i, j, model; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function create_edge!(i, j, model::GraphModelFixGrTop; kwargs...)
    _static_graph_error()
end

"""
$(TYPEDSIGNATURES)
"""
function create_edge!(edge, model::GraphModelFixGrTop; kwargs...)
    _static_graph_error()
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _kill_edges_and_shift!(node::Int, graph::SimplePropGraph, dead_graph, tick::Int)
    n=0
    structure = copy(graph.structure[node])
    for j in structure
        i,k = j>node ? (node, j) : (j, node)
        _shift_edge_from_alive_to_dead(graph, dead_graph, i,k) 
        graph.edgesprops[(i,k)]._extras._active = false
        bt, dt = graph.edgesprops[(i,k)]._extras._bd_times[end]::Tuple{Int, Int}
        graph.edgesprops[(i,k)]._extras._bd_times[end] = (bt, tick)
        n+=1
    end
    return n
end

"""
$(TYPEDSIGNATURES)

Adds an edge with properties `kwargs` to model graph. 
"""
@inline function _kill_edges_and_shift!(node::Int, graph::DirPropGraph, dead_graph, tick::Int)
    n = 0 
    in_structure = copy(graph.in_structure[node])
    out_structure = copy(graph.out_structure[node])
    for j in in_structure
        _shift_edge_from_alive_to_dead(graph, dead_graph, j,node) 
        graph.edgesprops[(j,node)]._extras._active = false
        bt, dt = graph.edgesprops[(j,node)]._extras._bd_times[end]::Tuple{Int, Int}
        graph.edgesprops[(j,node)]._extras._bd_times[end] = (bt, tick)
        n+=1
    end
    for j in out_structure
        _shift_edge_from_alive_to_dead(graph, dead_graph, node, j) 
        graph.edgesprops[(node,j)]._extras._active = false
        bt, dt = graph.edgesprops[(node,j)]._extras._bd_times[end]::Tuple{Int, Int}
        graph.edgesprops[(node,j)]._extras._bd_times[end] = (bt, tick)
        n+=1
    end
    return n
end


"""
$(TYPEDSIGNATURES)

adds an edge with properties `kwargs` to model graph. 
"""
@inline function _clear_node!(node, model::GraphModelDynAgNum)
    ids = copy(model.graph.nodesprops[node].agents) #agents present in a container must be all active as inactive agents are removed from the agent list at their node
    for id in ids
        agent = agent_with_id(id, model)
        deleteat!(model.graph.nodesprops[node].agents, findfirst(m->m==id, model.graph.nodesprops[node].agents))
        agent._extras._active = false
        agent._extras._death_time = model.tick
        model.parameters._extras._num_agents::Int -= 1 # number of active agents
        push!(model.agents_killed, agent)
    end
    return true
end


"""
$(TYPEDSIGNATURES)

adds an edge with properties `kwargs` to model graph. 
"""
@inline function _clear_node!(node, model::GraphModelFixAgNum)
    if length(model.graph.nodesprops[node].agents)>0
        return false
    end
    return true
end


"""
$(TYPEDSIGNATURES)

Removes a node from model graph. For performance reasons the function does not check if the node contains the node so it will
throw an error if the user tries to delete a node which is not there. Also the node will not be deleted if the agents in the model
can not be killed and the number of agents at the given node is nonzero.
"""
function kill_node!(node, model::GraphModelDynGrTop)
    if model.graph.nodesprops[node]._extras._active::Bool
        if !(model.parameters._extras._keep_deads_data::Bool)
            condition = _clear_node!(node, model)     
            if !condition
                return
            end  
            n = _rem_vertex_f!(model.graph, node)
            model.parameters._extras._num_all_verts::Int -=1
            model.parameters._extras._num_verts::Int -=1
            model.parameters._extras._num_edges::Int -=n
            if model.parameters._extras._num_all_verts::Int >0
                model.parameters._extras._max_node_id = getfield(model.graph, :_nodes)[model.parameters._extras._num_all_verts::Int]
            else
                model.parameters._extras._max_node_id = 0 
            end
            return
        end
        condition = _clear_node!(node, model)     
        if !condition
            return
        end  
        dead_graph = model.dead_meta_graph
        n = _kill_edges_and_shift!(node, model.graph,dead_graph, model.tick)
        _shift_node_from_alive_to_dead(model.graph, dead_graph, node)
        model.graph.nodesprops[node]._extras._active = false
        model.graph.nodesprops[node]._extras._death_time= model.tick
        model.parameters._extras._num_verts::Int -= 1
        model.parameters._extras._num_edges::Int -= n
    end
end

"""
$(TYPEDSIGNATURES)
"""
function kill_node!(node, model::GraphModelFixGrTop)
    _static_graph_error()
end


@inline function _shift_edge_from_alive_to_dead(graph::SimplePropGraph, dead_graph, i, j)
    deleteat!(graph.structure[j], findfirst(x->x==i,graph.structure[j]))
    deleteat!(graph.structure[i], findfirst(x->x==j,graph.structure[i]))
    push!(dead_graph.structure[i], j)
    push!(dead_graph.structure[j], i) 
    dead_graph.edgesprops[(i,j)] = graph.edgesprops[(i,j)]
end

@inline function _shift_edge_from_alive_to_dead(graph::DirPropGraph, dead_graph, i, j)
    deleteat!(graph.in_structure[j], findfirst(x->x==i,graph.in_structure[j]))
    deleteat!(graph.out_structure[i], findfirst(x->x==j,graph.out_structure[i]))
    push!(dead_graph.out_structure[i], j)
    push!(dead_graph.in_structure[j], i) 
    dead_graph.edgesprops[(i,j)] = graph.edgesprops[(i,j)]
end

@inline function _shift_node_from_alive_to_dead(graph::AbstractPropGraph, dead_graph, node)
    deleteat!(getfield(graph, :_nodes), searchsortedfirst(getfield(graph, :_nodes), node))
    push!(getfield(dead_graph, :_nodes), node)
    dead_graph.nodesprops[node] = graph.nodesprops[node]
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _kill_edge_condition(i,j,graph::SimplePropGraph, model::GraphModelDynGrTop)
    i, j = i>j ? (j,i) : (i,j)
    condition = (i in graph.structure[j])
    dead_graph = model.dead_meta_graph
    keep_deads_data = model.parameters._extras._keep_deads_data::Bool
    if condition 
        if !keep_deads_data
            _rem_edge_f!(graph, i,j)
            model.parameters._extras._num_edges::Int -= 1
            return
        end
        graph.edgesprops[(i,j)]._extras._active = false
        bt, dt = graph.edgesprops[(i,j)]._extras._bd_times[end]::Tuple{Int, Int}
        graph.edgesprops[(i,j)]._extras._bd_times[end] = (bt, model.tick)
        model.parameters._extras._num_edges::Int -= 1
        # remove edges from graph and move them to dead_graph and don't remove edgesprops.
        _shift_edge_from_alive_to_dead(graph, dead_graph, i,j)  
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _kill_edge_condition(i,j,graph::DirPropGraph, model::GraphModelDynGrTop)
    condition = (j in graph.out_structure[i])
    dead_graph = model.dead_meta_graph
    keep_deads_data = model.parameters._extras._keep_deads_data::Bool
    if condition
        if !keep_deads_data
            _rem_edge_f!(graph, i,j)
            return
        end
        graph.edgesprops[(i,j)]._extras._active = false
        bt, dt = graph.edgesprops[(i,j)]._extras._bd_times[end]::Tuple{Int, Int}
        graph.edgesprops[(i,j)]._extras._bd_times[end] = (bt, model.tick)
        model.parameters._extras._num_edges::Int -= 1
        # remove edges from graph and move them to dead_graph and don't remove edgesprops.
        _shift_edge_from_alive_to_dead(graph, dead_graph, i,j)  
    end
end


"""
$(TYPEDSIGNATURES)

Removes edge from the model graph. 
"""
function kill_edge!(i,j, model::GraphModelDynGrTop) 
    graph = model.graph
    _kill_edge_condition(i,j,graph, model)
end

"""
$(TYPEDSIGNATURES)

Removes edge from the model graph.
"""
function kill_edge!(edge, model::GraphModelDynGrTop)
    i,j=edge
    kill_edge!(i,j,model)
end


"""
$(TYPEDSIGNATURES)
"""
function kill_edge!(i,j, model::GraphModelFixGrTop) 
    _static_graph_error()
end

"""
$(TYPEDSIGNATURES)
"""
function kill_edge!(edge, model::GraphModelFixGrTop) 
    _static_graph_error()
end

"""
$(TYPEDSIGNATURES)

Removes all edges from the model graph.
"""
function kill_all_edges!(model::GraphModelDynGrTop)
    for edge in edges(model.graph)
        kill_edge!(edge, model)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function kill_all_edges!(model::GraphModelFixGrTop) 
    _static_graph_error()
end


"""
$(TYPEDSIGNATURES)
"""
function _permanently_remove_dead_graph_data!(model::GraphModelDynGrTop)
    if !(model.parameters._extras._keep_deads_data::Bool)
        empty!(model.dead_meta_graph)
    else
        for node in keys(model.dead_meta_graph.nodesprops)
            delete!(model.graph.nodesprops, node)
        end
        for edge in keys(model.dead_meta_graph.edgesprops)
            delete!(model.graph.edgesprops, edge)
        end
        empty!(model.dead_meta_graph)
        _refill_dead_meta_graph!(model.dead_meta_graph, model.graph)

        nodes = getfield(model.graph, :_nodes)
        len_nodes = length(nodes)
        model.parameters._extras._num_verts = len_nodes
        model.parameters._extras._num_all_verts = len_nodes
        model.parameters._extras._max_node_id = len_nodes > 0 ? max(nodes...) : 0
    end
end


"""
$(TYPEDSIGNATURES)
"""
_permanently_remove_dead_graph_data!(model::GraphModelFixGrTop) = nothing


"""
$(TYPEDSIGNATURES)
"""
function _reshift_node_numbers(model::GraphModelDynGrTop)

end



"""
$(TYPEDSIGNATURES)
"""
_reshift_node_numbers(model::GraphModelFixGrTop) = nothing




"""
$(TYPEDSIGNATURES)
"""
@inline function update_nodes_record!(model::GraphModel)
    if length(model.record.nprops)>0
        for node in getfield(model.graph, :_nodes)
            node_dict = unwrap(model.graph.nodesprops[node])
            node_data = unwrap_data(model.graph.nodesprops[node])
            for key in model.record.nprops
                push!(node_data[key], node_dict[key])
            end
        end
    end       
end





"""
$(TYPEDSIGNATURES)
"""
@inline function update_edges_record!(model::GraphModel)
    if length(model.record.eprops)>0
        for edge in edges(model.graph)
            edge_dict = unwrap(model.graph.edgesprops[edge])
            edge_data = unwrap_data(model.graph.edgesprops[edge])
            for key in model.record.eprops
                push!(edge_data[key], edge_dict[key])
            end
        end
    end    
end


"""
$(TYPEDSIGNATURES)
"""
function update_agents_record!(model::GraphModel) #update is done when all agents in model.agents are active
    for agent in model.agents
        _update_agent_record!(agent)
    end
end




"""
$(TYPEDSIGNATURES)
"""
function do_after_model_step!(model::GraphModelDynAgNum)
    
    _permanently_remove_inactive_agents!(model)  # permanent removal simply means storing in a different place unless `keep_deads_data` is false.


    commit_add_agents!(model) 

    update_agents_record!(model)

    update_nodes_record!(model)   

    update_edges_record!(model)   

    _update_model_record!(model)

    getfield(model, :tick)[] +=1
end


"""
$(TYPEDSIGNATURES)
"""
function do_after_model_step!(model::GraphModelFixAgNum)

    update_agents_record!(model)

    update_nodes_record!(model)   

    update_edges_record!(model)   

    _update_model_record!(model)

    getfield(model, :tick)[] +=1
end



####################
####################

####################
####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_active_out_structure(graph::AbstractPropGraph{Mortal}, vert, out_structure, frame)
    active_out_structure = Int[]
    indices = Int[]
    for nd in out_structure
        bd_times = graph.edgesprops[(vert, nd)]._extras._bd_times::Vector{Tuple{Int, Int}}
        len = 0 # if initial data is stored there will be atleast 1 element 
        for (birth_time,death_time) in bd_times
            if (birth_time<=frame)&&(frame<=death_time)
                push!(active_out_structure, nd)
                push!(indices, frame - birth_time+len+1)
                break
            end
            if death_time < typemax(Int)
                len+=death_time - birth_time +1
            end
        end
    end
    return active_out_structure, indices
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_active_out_structure(graph::AbstractPropGraph{Static}, vert, out_structure, frame)
    return out_structure
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_da_vert(graph::AbstractPropGraph{Mortal}, vert, node_size, frame, nprops)
    vert_pos = _get_vert_pos(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)
    out_structure = out_links(graph, vert)
    active_out_structure, indices = _get_active_out_structure(graph, vert, out_structure, frame)
    neighs_pos = [_get_vert_pos(graph, nd, frame, nprops) for nd in active_out_structure]
    draw_vert(vert_pos, vert_col, node_size, neighs_pos, is_digraph(graph))
end

@inline function _draw_da_vert(graph::AbstractPropGraph{Static}, vert, node_size, frame, nprops)
    vert_pos = _get_vert_pos(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)
    out_structure = out_links(graph, vert)
    neighs_pos = [_get_vert_pos(graph, nd, frame, nprops) for nd in out_structure]
    draw_vert(vert_pos, vert_col, node_size, neighs_pos, is_digraph(graph))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_graph(graph::AbstractPropGraph{Mortal}, verts, node_size, frame, nprops)
    alive_verts = verts[[(graph.nodesprops[nd]._extras._birth_time::Int <=frame)&&(frame<=graph.nodesprops[nd]._extras._death_time::Int) for nd in verts]]
    @sync for vert in alive_verts
        @async _draw_da_vert(graph, vert, node_size, frame, nprops) 
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_graph(graph::AbstractPropGraph{Static}, verts, node_size, frame, nprops)
    nothing
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_graph(model::GraphModelDynAgNum, graph, verts, node_size, frame, scl)
    if model.parameters._extras._show_space::Bool
        _draw_graph(graph, verts, node_size, frame, model.record.nprops)
    end

    all_agents = vcat(model.agents, model.agents_killed)

    @sync for agent in all_agents
        if (agent._extras._birth_time::Int <= frame)&&(frame<= agent._extras._death_time::Int)
            @async draw_agent(agent, model, graph, node_size, scl, frame - agent._extras._birth_time::Int + 1, frame)
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_graph(model::GraphModelFixAgNum, graph, verts, node_size, frame, scl)

    if model.parameters._extras._show_space::Bool
        _draw_graph(graph, verts, node_size, frame, model.record.nprops)
    end

    @sync for agent in model.agents
       @async draw_agent(agent, model, graph, node_size, scl, frame, frame)
    end
end












