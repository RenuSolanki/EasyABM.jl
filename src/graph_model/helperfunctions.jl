"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
function manage_default_graphics_data!(agent::AgentDictGr, graphics, default_node)
    if graphics
        if !haskey(agent, :node)
            agent.node = default_node
        end
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
@inline function _create_a_node!(model::GraphModelDynGrTop)
    num = model.parameters._extras._max_node_id+1
    _add_vertex!(model.graph, num)
    madict = PropDataDict() 
    madict._extras._agents = Int[]
    madict._extras._active = true
    madict._extras._birth_time = model.tick
    madict._extras._death_time = Inf
    model.graph.nodesprops[num] = madict
    empty!(model.record.nprops)
    model.parameters._extras._num_verts += 1
    model.parameters._extras._num_all_verts += 1
    model.parameters._extras._max_node_id = num
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _create_a_node!(model::GraphModelFixGrTop) #in the rare case when use creates models with an empty graph
    num = model.parameters._extras._max_node_id+1
    _add_vertex!(model.graph, num)
    madict = PropDataDict()
    madict._extras._agents = Int[]
    model.graph.nodesprops[num] = madict
    empty!(model.record.nprops)
    model.parameters._extras._num_verts += 1
    model.parameters._extras._num_all_verts += 1
    model.parameters._extras._max_node_id = num
end




"""
$(TYPEDSIGNATURES)

Adds the agent to the model.
"""
function add_agent!(agent, model::GraphModelDynAgNum)
    if !haskey(agent._extras, :_id)
        if model.parameters._extras._num_verts == 0
            _create_a_node!(model)
        end
    
        verts = get_nodes(model)
        len_verts = model.parameters._extras._num_verts #number of active verts

        if !haskey(agent, :node) || !(agent.node in verts)
            if model.parameters._extras._random_positions
                default_node = verts[rand(1:len_verts)]
                agent.node = default_node # if random_positions is true, we need to assign a pos property
            else
                default_node = verts[1]
            end
        end

        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics, default_node)


        if haskey(agent, :node)
            node = agent.node 
            if node in verts
                push!(model.graph.nodesprops[node]._extras._agents, agent._extras._id)
                agent._extras._last_node_loc = node   
            else
                agent.node = default_node
                push!(model.graph.nodesprops[default_node]._extras._agents, agent._extras._id)
                agent._extras._last_node_loc = default_node
            end
        end

        agent._extras._nodesprops = model.graph.nodesprops

        _create_agent_record!(agent, model)

        _init_agent_record!(agent)

        getfield(model,:max_id)[] +=1
        model.parameters._extras._num_agents += 1 #active agents
        model.parameters._extras._len_model_agents +=1 # len(model.agents)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _create_node_structure!(node, graph::SimplePropGraph)
    push!(getfield(graph, :_nodes), node)
    graph.structure[node] = Int[]
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _create_node_structure!(node, graph::DirPropGraph)
    push!(getfield(graph, :_nodes), node)
    graph.in_structure[node] = Int[]
    graph.out_structure[node] = Int[]
end

"""
$(TYPEDSIGNATURES)

Adds a node with properties specified in `kwargs` to the model's graph.
"""
function add_node!(model::GraphModelDynGrTop; kwargs...)
    node = model.parameters._extras._max_node_id+1
    _create_node_structure!(node, model.graph)
    madict = PropDataDict(Dict{Symbol, Any}(kwargs))
    madict._extras._agents=Int[]
    madict._extras._active=true
    madict._extras._birth_time = model.tick
    madict._extras._death_time=Inf
    model.graph.nodesprops[node] = madict
    model.parameters._extras._num_verts +=1
    model.parameters._extras._num_all_verts+=1
    model.parameters._extras._max_node_id = node
    if model.graphics && !haskey(model.graph.nodesprops[node], :pos) && !haskey(model.graph.nodesprops[node]._extras, :_pos)
        model.graph.nodesprops[node]._extras._pos = (rand()*_scale_graph+_boundary_frame, rand()*_scale_graph+_boundary_frame)
    end
    if length(model.record.nprops)>0
        node_dict = unwrap(model.graph.nodesprops[node])
        node_data = unwrap_data(model.graph.nodesprops[node])
        for key in model.record.nprops
            push!(node_data[key], node_dict[key])
        end
    end

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

Adds an edge with properties `kwargs` to model graph. 
"""
function create_edge!(i, j, model::GraphModelDynGrTop; kwargs...)
    nodes = getfield(model.graph, :_nodes)
    i,j,condition = _add_edge_condition(nodes,i,j,model.graph)
    if condition
        _update_edge_structure!(i, j, model.graph)
        madict = PropDataDict(Dict{Symbol, Any}(kwargs))
        madict._extras._active=true
        madict._extras._birth_time = model.tick
        madict._extras._death_time=Inf
        model.parameters._extras._num_edges +=1
        model.graph.edgesprops[(i,j)] = madict
        if length(model.record.eprops)>0
            edge_dict = unwrap(model.graph.edgesprops[(i,j)])
            edge_data = unwrap_data(model.graph.edgesprops[(i,j)])
            for key in model.record.eprops
                push!(edge_data[key], edge_dict[key])
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
@inline function _kill_edges_at!(node::Int, graph::SimplePropGraph, tick::Int)
    n=0
    structure = graph.structure[node]
    for j in structure
        i,k = j>node ? (node, j) : (j, node)
        if graph.edgesprops[(i,k)]._extras._active
            graph.edgesprops[(i,k)]._extras._active = false
            graph.edgesprops[(i,k)]._extras._death_time = tick
            n+=1
        end
    end
    return n
end

"""
$(TYPEDSIGNATURES)

Adds an edge with properties `kwargs` to model graph. 
"""
@inline function _kill_edges_at!(node::Int, graph::DirPropGraph, tick::Int)
    n = 0 
    for j in graph.in_structure[node]
        if graph.edgesprops[(j,node)]._extras._active
            graph.edgesprops[(j,node)]._extras._active = false
            graph.edgesprops[(j,node)]._extras._death_time = tick
            n+=1
        end
    end
    for j in graph.out_structure[node]
        if graph.edgesprops[(node,j)]._extras._active
            graph.edgesprops[(node,j)]._extras._active = false
            graph.edgesprops[(node,j)]._extras._death_time = tick
            n+=1
        end
    end
    return n
end


"""
$(TYPEDSIGNATURES)

adds an edge with properties `kwargs` to model graph. 
"""
@inline function _clear_and_kill_node!(node, model::GraphModelDynAgNum)
    ids = copy(model.graph.nodesprops[node]._extras._agents) #agents present in a container must be all active as inactive agents are removed from the agent list at their node
    for id in ids
        agent = agent_with_id(id, model)
        deleteat!(model.graph.nodesprops[node]._extras._agents, findfirst(m->m==id, model.graph.nodesprops[node]._extras._agents))
        agent._extras._active = false
        agent._extras._death_time = model.tick
    end
    n = _kill_edges_at!(node, model.graph, model.tick)
    model.graph.nodesprops[node]._extras._active = false
    model.graph.nodesprops[node]._extras._death_time= model.tick
    model.parameters._extras._num_verts -= 1
    model.parameters._extras._num_edges -= n
end


"""
$(TYPEDSIGNATURES)

adds an edge with properties `kwargs` to model graph. 
"""
@inline function _clear_and_kill_node!(node, model::GraphModelFixAgNum)
    if length(model.graph.nodesprops[node]._extras._agents)>0
        return
    end
    n = _kill_edges_at!(node, model.graph, model.tick)
    model.graph.nodesprops[node]._extras._active = false
    model.graph.nodesprops[node]._extras._death_time= model.tick
    model.parameters._extras._num_verts -= 1   
    model.parameters._extras._num_edges -= n
end


"""
$(TYPEDSIGNATURES)

Removes a node from model graph. For performance reasons the function does not check if the node contains the node so it will
throw an error if the user tries to delete a node which is not there. Also the node will not be deleted if the agents in the model
can not be killed and the number of agents at the given node is nonzero.
"""
function kill_node!(node, model::GraphModelDynGrTop)
    if model.graph.nodesprops[node]._extras._active 
       _clear_and_kill_node!(node, model)       
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _kill_edge_condition(i,j,graph::SimplePropGraph)
    i, j = i>j ? (j,i) : (i,j)
    condition = (i in graph.structure[j])&&(graph.edgesprops[(i,j)]._extras._active)
    return i,j,condition
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _kill_edge_condition(i,j,graph::DirPropGraph)
    condition = (j in graph.out_structure[i])&&(graph.edgesprops[(i,j)]._extras._active)
    return i, j, condition
end


"""
$(TYPEDSIGNATURES)

Removes edge from the model graph. 
"""
function kill_edge!(i,j, model::GraphModelDynGrTop)
    
    i,j,condition = _kill_edge_condition(i,j,model.graph)

    if condition
        model.graph.edgesprops[(i,j)]._extras._active = false
        model.graph.edgesprops[(i,j)]._extras._death_time  = model.tick
        model.parameters._extras._num_edges -= 1
    end
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
function _permanently_remove_inactive_nodes!(model::GraphModelDynGrTop)
    verts = getfield(model.graph, :_nodes)
    nodes_to_remove = verts[[!(model.graph.nodesprops[vt]._extras._active) for vt in verts]]
    for node in nodes_to_remove
        _rem_vertex_f!(model.graph, node)
        model.parameters._extras._num_all_verts -=1
    end
    if model.parameters._extras._num_all_verts >0
        model.parameters._extras._max_node_id = getfield(model.graph, :_nodes)[model.parameters._extras._num_all_verts]
    else
        model.parameters._extras._max_node_id = 0 
    end
end

"""
$(TYPEDSIGNATURES)
"""
_permanently_remove_inactive_nodes!(model::GraphModelFixGrTop) = nothing

"""
$(TYPEDSIGNATURES)
"""
function _permanently_remove_inactive_edges!(model::GraphModelDynGrTop)
    eds = edges(model.graph)
    edges_to_remove = eds[[!(model.graph.edgesprops[ed]._extras._active) for ed in eds]]
    for edge in edges_to_remove
        _rem_edge_f!(model.graph, edge[1], edge[2])
    end
end

"""
$(TYPEDSIGNATURES)
"""
_permanently_remove_inactive_edges!(model::GraphModelFixGrTop) = nothing



"""
$(TYPEDSIGNATURES)
"""
@inline function update_nodes_record!(model::GraphModelDynGrTop)
    if length(model.record.nprops)>0
        for node in getfield(model.graph, :_nodes)
            if model.graph.nodesprops[node]._extras._active
                node_dict = unwrap(model.graph.nodesprops[node])
                node_data = unwrap_data(model.graph.nodesprops[node])
                for key in model.record.nprops
                    push!(node_data[key], node_dict[key])
                end
            end
        end
    end       
end


"""
$(TYPEDSIGNATURES)
"""
@inline function update_nodes_record!(model::GraphModelFixGrTop)
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
@inline function update_edges_record!(model::GraphModelDynGrTop)
    if length(model.record.eprops)>0
        for edge in edges(model.graph)
            if model.graph.edgesprops[edge]._extras._active
                edge_dict = unwrap(model.graph.edgesprops[edge])
                edge_data = unwrap_data(model.graph.edgesprops[edge])
                for key in model.record.eprops
                    push!(edge_data[key], edge_dict[key])
                end
            end
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function update_edges_record!(model::GraphModelFixGrTop)
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
function update_agents_record!(model::GraphModelDynAgNum) 
    for agent in model.agents
        if agent._extras._active
            _update_agent_record!(agent)
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
function update_agents_record!(model::GraphModelFixAgNum) 
    for agent in model.agents
        _update_agent_record!(agent)
    end
end




"""
$(TYPEDSIGNATURES)
"""
function do_after_model_step!(model::GraphModelDynAgNum)
    
    _permanently_remove_inactive_agents!(model)  # permanent removal simply means storing in a different place unless `keep_deads_data` is false.
    
    if !(model.parameters._extras._keep_deads_data)
        _permanently_remove_inactive_nodes!(model)
        _permanently_remove_inactive_edges!(model)
    end

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

    if !(model.parameters._extras._keep_deads_data)
        _permanently_remove_inactive_nodes!(model)
        _permanently_remove_inactive_edges!(model)
    end

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
@inline function _draw_da_vert(graph::AbstractPropGraph{MortalType}, vert, node_size, frame, nprops)
    vert_pos = _get_vert_pos(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)
    out_structure = out_links(graph, vert)
    active_out_structure = out_structure[[(graph.edgesprops[(vert, nd)]._extras._birth_time <= frame)&&(frame<=graph.edgesprops[(vert, nd)]._extras._death_time) for nd in out_structure]]
    neighs_pos = [_get_vert_pos(graph, nd, frame, nprops) for nd in active_out_structure]
    draw_vert(vert_pos, vert_col, node_size, neighs_pos, is_digraph(graph))
end

@inline function _draw_da_vert(graph::AbstractPropGraph{StaticType}, vert, node_size, frame, nprops)
    vert_pos = _get_vert_pos(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)
    out_structure = out_links(graph, vert)
    neighs_pos = [_get_vert_pos(graph, nd, frame, nprops) for nd in out_structure]
    draw_vert(vert_pos, vert_col, node_size, neighs_pos, is_digraph(graph))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_graph(graph::AbstractPropGraph{MortalType}, verts, node_size, frame, nprops)
    alive_verts = verts[[(graph.nodesprops[nd]._extras._birth_time <=frame)&&(frame<=graph.nodesprops[nd]._extras._death_time) for nd in verts]]
    @sync for vert in alive_verts
        @async _draw_da_vert(graph, vert, node_size, frame, nprops) 
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_graph(graph::AbstractPropGraph{StaticType}, verts, node_size, frame, nprops)
    nothing
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_graph(model::GraphModelDynAgNum, verts, node_size, frame, scl)
    if model.parameters._extras._show_space
        _draw_graph(model.graph, verts, node_size, frame, model.record.nprops)
    end

    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)

    @sync for agent in all_agents
        if (agent._extras._birth_time <= frame)&&(frame<= agent._extras._death_time)
            @async draw_agent(agent, model, node_size, scl, frame - agent._extras._birth_time + 1, frame)
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_graph(model::GraphModelFixAgNum, verts, node_size, frame, scl)

    if model.parameters._extras._show_space
        _draw_graph(model.graph, verts, node_size, frame, model.record.nprops)
    end

    @sync for agent in model.agents
       @async draw_agent(agent, model, node_size, scl, frame, frame)
    end
end












