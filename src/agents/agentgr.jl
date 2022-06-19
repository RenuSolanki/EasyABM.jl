mutable struct AgentDictGr{K, V} <: AbstractPropDict{K, V}
    node::Int
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    AgentDictGr() = new{Symbol, Any}(1, Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function AgentDictGr(node, d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()  
        new{Symbol, Any}(node, d, data)
    end
end

Base.IteratorSize(::Type{AgentDictGr{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{AgentDictGr{T}}) where T = IteratorEltype(T)


function update_nodesprops!(agent::AgentDictGr, model::Nothing)
    return
end

function update_nodesprops!(agent::AgentDictGr, graph::AbstractPropGraph{StaticType}, node_new)
    node_old = agent.node

    if node_new != node_old
        i = agent._extras._id
        nodesprops = graph.nodesprops
        deleteat!(nodesprops[node_old]._extras._agents, findfirst(x->x==i, nodesprops[node_old]._extras._agents))
        push!(nodesprops[node_new]._extras._agents, i)
        setfield!(agent, :node, node_new)
    end
end


function update_nodesprops!(agent::AgentDictGr, graph::AbstractPropGraph{MortalType}, node_new)
    if !graph.nodesprops[node_new]._extras._active
        return 
    else
        node_old = agent.node

        if node_new != node_old
            i = agent._extras._id
            nodesprops = graph.nodesprops
            deleteat!(nodesprops[node_old]._extras._agents, findfirst(x->x==i, nodesprops[node_old]._extras._agents))
            push!(nodesprops[node_new]._extras._agents, i)
            setfield!(agent, :node, node_new)
        end

    end 
end


function Base.getproperty(d::AgentDictGr, n::Symbol)
    if n == :node
        return getfield(d, :node)
    else
        return getindex(d, n)
    end
end

function Base.setproperty!(agent::AgentDictGr, key::Symbol, x)

    if !(agent._extras._active)
        return
    end
    
    dict = unwrap(agent)
    
    if key != :node
        dict[key] = x
    else 
        update_nodesprops!(agent, agent._extras._graph, x)
    end

end

function Base.show(io::IO, ::MIME"text/plain", a::AgentDictGr) # works with REPL
    println(io, "AgentGr:")
    println(io, " node: ", a.node)
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::AgentDictGr) # works with print
    println(io, "AgentGr:")
    println(io, " node: ", a.node)
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
function graph_agent(;node=1,kwargs...)
    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._graph = nothing
    dict_agent[:_extras]._active = true

    return AgentDictGr(node,dict_agent)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n graph agents with properties specified as keyword arguments.
"""
function graph_agents(n::Int;node=1, kwargs...)
list = Vector{AgentDictGr{Symbol, Any}}()
for i in 1:n
    agent = graph_agent(;node=node, kwargs...)
    push!(list, agent)
end
return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n graph agents all having same properties as `agent`.  
"""
function create_similar(agent::AgentDictGr, n::Int)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    node = agent.node
    agents = graph_agents(n;node=node, dc...)
    return agents
end

"""
$(TYPEDSIGNATURES)
Returns an agent with same properties as given `agent`. 
"""
function create_similar(agent::AgentDictGr)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    node = agent.node
    agent = graph_agent(;node=node,dc...)
    return agent
end



