struct AgentDictGr{K, V} <: AbstractPropDict{K, V}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    AgentDictGr() = new{Symbol, Any}(Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function AgentDictGr(d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()
        for (key,value) in d
            if !(key == :_extras) && !(key == :keeps_record_of)
                data[key]=typeof(value)[]
            end
        end    
        new{Symbol, Any}(d, data)
    end
end

Base.IteratorSize(::Type{AgentDictGr{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{AgentDictGr{T}}) where T = IteratorEltype(T)


function update_nodesprops!(agent::AgentDictGr, node_info::Nothing)
    nothing
end

function update_nodesprops!(agent::AgentDictGr, nodesprops::Dict{Int, Union{PropDataDict{Symbol, Any},Bool}})
    static_graph = nodesprops[-1]
    fix_agents_num = nodesprops[-2]
    if fix_agents_num || agent._extras._active
        if !static_graph
            if !nodesprops[agent.node]._extras._active # we rely on user to check (agent.node in keys(nodesprops) / nodes of graph) before setting node of agent. 
                unwrap(agent)[:node] = agent._extras._last_node_loc
                return 
            end
            node_new = agent.node
            node_old = agent._extras._last_node_loc
            i = agent._extras._id

            if node_new != node_old
                deleteat!(nodesprops[node_old]._extras._agents, findfirst(x->x==i, nodesprops[node_old]._extras._agents))
                push!(nodesprops[node_new]._extras._agents, i)
                agent._extras._last_node_loc = node_new  
            end

        else
            node_new = agent.node
            node_old = agent._extras._last_node_loc
            i = agent._extras._id

            if node_new != node_old
                deleteat!(nodesprops[node_old]._extras._agents, findfirst(x->x==i, nodesprops[node_old]._extras._agents))
                push!(nodesprops[node_new]._extras._agents, i)
                agent._extras._last_node_loc = node_new  
            end

        end
    end
    
end




function Base.setproperty!(agent::AgentDictGr, key::Symbol, x)

    if key == :_extras
        throw(StaticPropException("Can not modify private property : $key"))
    end

    if !(agent._extras._active)
        return
    end
    
    dict = unwrap(agent)
    dict_data = unwrap_data(agent)

    dict[key] = x

    if key==:node 
        update_nodesprops!(agent, agent._extras._nodesprops)
    end

    if !(key in keys(dict_data)) && !(key == :_extras) && !(key == :keeps_record_of)
        dict_data[key] = typeof(dict[key])[]
    end

end

function Base.show(io::IO, ::MIME"text/plain", a::AgentDictGr) # works with REPL
    println(io, "AgentGr:")
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::AgentDictGr) # works with print
    println(io, "AgentGr:")
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::Vector{AgentDictGr}) # works with REPL
    println(io, "AgentGr list with $(length(v)) agents.")
end

function Base.show(io::IO, v::Vector{AgentDictGr}) # works with print
    println(io, "AgentGr list with $(length(v)) agents.")
end


"""
$(TYPEDSIGNATURES)

Creates a single graph agent with properties specified as keyword arguments.
Following property names are reserved for some specific agent properties 
    - node : node where the agent is located on the graph. 
    - shape : shape of agent
    - color : color of agent
    - size : size of agent
    - orientation : orientation of agent
    - keeps_record_of : list of properties that the agent records during time evolution. 
"""
function create_graph_agent(;kwargs...)
    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._nodesprops = nothing
    dict_agent[:_extras]._active = true

    return AgentDictGr(dict_agent)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n graph agents with properties specified as keyword arguments.
"""
function create_graph_agents(n::Int; kwargs...)
list = Vector{AgentDictGr{Symbol, Any}}()
for i in 1:n
    agent = create_graph_agent(;kwargs...)
    push!(list, agent)
end
return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n graph agents all having same properties as `agent`.  
"""
function create_graph_agents(n::Int, agent::AgentDictGr)
list = Vector{AgentDictGr{Symbol, Any}}()
ag = deepcopy(agent)
if haskey(ag._extras, :_id)
    delete!(unwrap(ag._extras), :_id)
end
for i in 1:n
    agent_new = deepcopy(ag)
    push!(list, agent_new)
end
return list
end



