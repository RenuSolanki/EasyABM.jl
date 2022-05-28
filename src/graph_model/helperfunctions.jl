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
    num = length(vertices(model.graph))+1
    _add_vertex!(model.graph, num)
    madict = PropDataDict() 
    madict._extras._agents = Int[]
    madict._extras._active = true
    madict._extras._birth_time = model.tick
    madict._extras._death_time = Inf
    model.graph.nodesprops[num] = madict
    empty!(model.record.nprops)
    model.parameters._extras._num_verts = 1
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _create_a_node!(model::GraphModelFixGrTop)
    num = length(vertices(model.graph))+1
    _add_vertex!(model.graph, num)
    madict = PropDataDict()
    madict._extras._agents = Int[]
    model.graph.nodesprops[num] = madict
    empty!(model.record.nprops)
    model.parameters._extras._num_verts = 1
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
    
        verts = get_nodes(model.graph)

        if !haskey(agent, :node) || !(agent.node in verts)
            if model.parameters._extras._random_positions
                default_node = verts[rand(1:length(verts))]
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
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _create_node_structure!(node, graph::SimplePropGraph)
    graph.structure[node] = Int[]
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _create_node_structure!(node, graph::DirPropGraph)
    graph.in_structure[node] = Int[]
    graph.out_structure[node] = Int[]
end

"""
$(TYPEDSIGNATURES)

Adds a node with properties specified in `kwargs` to the model's graph.
"""
function add_node!(node, model::GraphModelDynGrTop; kwargs...)
    if node<0
        println("Only positive number nodes are allowed!")
        return
    end
    nodes = vertices(model.graph)
    if !(node in nodes)
        _create_node_structure!(node, model.graph)
        madict = PropDataDict(Dict{Symbol, Any}(kwargs))
        madict._extras._agents=Int[]
        madict._extras._active=true
        madict._extras._birth_time = model.tick
        madict._extras._death_time=Inf
        model.graph.nodesprops[node] = madict
        model.parameters._extras._num_verts +=1
        if model.graphics && !haskey(model.graph.nodesprops[node]._extras, :_pos)
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
    nodes = vertices(model.graph)
    i,j,condition = _add_edge_condition(nodes,i,j,model.graph)
    if condition
        _update_edge_structure!(i, j, model.graph)
        madict = PropDataDict(Dict{Symbol, Any}(kwargs))
        madict._extras._active=true
        madict._extras._birth_time = model.tick
        madict._extras._death_time=Inf
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
    structure = graph.structure[node]
    for j in structure
        i,k = j>node ? (node, j) : (j, node)
        if graph.edgesprops[(i,k)]._extras._active
            graph.edgesprops[(i,k)]._extras._active = false
            graph.edgesprops[(i,k)]._extras._death_time = tick
        end
    end
end

"""
$(TYPEDSIGNATURES)

Adds an edge with properties `kwargs` to model graph. 
"""
@inline function _kill_edges_at!(node::Int, graph::DirPropGraph, tick::Int)
    for j in graph.in_structure[node]
        if graph.edgesprops[(j,node)]._extras._active
            graph.edgesprops[(j,node)]._extras._active = false
            graph.edgesprops[(j,node)]._extras._death_time = tick
        end
    end
    for j in graph.out_structure[node]
        if graph.edgesprops[(node,j)]._extras._active
            graph.edgesprops[(node,j)]._extras._active = false
            graph.edgesprops[(node,j)]._extras._death_time = tick
        end
    end
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
    _kill_edges_at!(node, model.graph, model.tick)
    model.graph.nodesprops[node]._extras._active = false
    model.graph.nodesprops[node]._extras._death_time= model.tick
    model.parameters._extras._num_verts -= 1
end


"""
$(TYPEDSIGNATURES)

adds an edge with properties `kwargs` to model graph. 
"""
@inline function _clear_and_kill_node!(node, model::GraphModelFixAgNum)
    if length(model.graph.nodesprops[node]._extras._agents)>0
        return
    end
    _kill_edges_at!(node, model.graph, model.tick)
    model.graph.nodesprops[node]._extras._active = false
    model.graph.nodesprops[node]._extras._death_time= model.tick
    model.parameters._extras._num_verts -= 1   
end


"""
$(TYPEDSIGNATURES)

Removes a node from model graph. 
"""
function kill_node!(node, model::GraphModelDynGrTop)
    if (node in vertices(model.graph)) && model.graph.nodesprops[node]._extras._active 
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
    verts = vertices(model.graph)
    nodes_to_remove = verts[[!(model.graph.nodesprops[vt]._extras._active) for vt in verts]]
    for node in nodes_to_remove
        _rem_vertex!(model.graph, node)
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
    edges = edges(model.graph)
    edges_to_remove = edges[[!(model.graph.edgesprops[ed]._extras._active) for ed in edges]]
    for edge in edges_to_remove
        _rem_edge!(model.graph, edge[1], edge[2])
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
        for node in vertices(model.graph)
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
        for node in vertices(model.graph)
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
    
    _permanently_remove_inactive_agents!(model)  # permanent removal simply means storing in a different place. We don't do that 
                                                 # with inactive nodes and edges during a simulation.

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
@inline function _draw_da_vert(graph::AbstractPropGraph{MortalType}, vert, node_size, frame, nprops)
    vert_pos = _get_vert_pos(graph, vert, frame, nprops)
    out_structure = out_links(graph, vert)
    active_out_structure = out_structure[[(graph.edgesprops[(vert, nd)]._extras._birth_time <= frame)&&(frame<=graph.edgesprops[(vert, nd)]._extras._death_time) for nd in out_structure]]
    neighs_pos = [_get_vert_pos(graph, nd, frame, nprops) for nd in active_out_structure]
    draw_vert(vert_pos, node_size, neighs_pos, is_directed(graph))
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
            @async draw_agent(agent, model, node_size, scl, frame - agent._extras._birth_time + 1)
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
       @async draw_agent(agent, model, node_size, scl, frame)
    end
end










