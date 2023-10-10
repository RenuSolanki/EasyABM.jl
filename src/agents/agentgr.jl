mutable struct GraphAgent{S<:MType, T<:MType} <: AbstractAgent{Symbol, Any} #S graph mortality
    id::Int
    node::Int
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    model::Union{AbstractGraphModel{S, T}, Nothing}
    GraphAgent() = new{Mortal, Mortal}(1, 1, 
    Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), 
    Dict{Symbol, Any}(), nothing)
    function GraphAgent{S, T}(id::Int, node::Int, d::Dict{Symbol, Any}, model) where {S<:MType, T<:MType}
        data = Dict{Symbol, Any}()  
        new{S, T}(id, node, d, data, model)
    end
    function GraphAgent{S, T}(id::Int, node::Int, d::Dict{Symbol, Any}, data::Dict{Symbol, Any}, model) where {S<:MType, T<:MType}
        new{S, T}(id, node, d, data, model)
    end
end


Base.IteratorSize(::Type{GraphAgent{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{GraphAgent{T}}) where T = IteratorEltype(T)


function Base.getproperty(d::GraphAgent, n::Symbol)
    if n == :node
        return getfield(d, :node)
    else
        return getindex(d, n)
    end
end


function Base.show(io::IO, ::MIME"text/plain", a::GraphAgent) # works with REPL
    println(io, "GraphAgent:")
    println(io, " node: ", a.node)
    for (key, value) in unwrap(a)
        if !(key == :_extras) && !(key == :_keeps_record_of)
            println(io, " ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::GraphAgent) # works with print
    println(io, "GraphAgent:")
    println(io, " node: ", a.node)
    for (key, value) in unwrap(a)
        if !(key == :_extras) && !(key == :_keeps_record_of)
            println(io, " ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::Vector{<:GraphAgent}) # works with REPL
    println(io, "GraphAgent list with $(length(v)) agents.")
end

function Base.show(io::IO, v::Vector{<:GraphAgent}) # works with print
    println(io, "GraphAgent list with $(length(v)) agents.")
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
    - `keeps_record_of` : Set of properties that the agent records during time evolution. 
"""
function graph_agent(;node=1,
    graph_mort_type::Type{S} = Static, 
    agent_type::Type{T}=Static,
    kwargs...) where {S<:MType, T<:MType}

    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:_keeps_record_of] = Set{Symbol}([])
    else
        dict_agent[:_keeps_record_of] = dict_agent[:keeps_record_of]
        delete!(dict_agent, :keeps_record_of)
    end
    
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._active = true
    dict_agent[:_extras]._new = true

    return GraphAgent{S, T}(1, node,dict_agent, nothing)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n graph agents with properties specified as keyword arguments.
"""
function graph_agents(n::Int; node=1, 
    graph_mort_type::Type{S} = Static, 
    agent_type::Type{T}=Static,
    kwargs...) where {S<:MType, T<:MType}

    list = Vector{GraphAgent{S, T}}()
    for i in 1:n
        agent = graph_agent(;node=node, graph_mort_type = S, agent_type=T, kwargs...)
        push!(list, agent)
    end
    return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n 2d agents all having same (other than _extras) properties as `agent`.  
"""
function create_similar(agent::GraphAgent{S, T}, n::Int) where {S<:MType, T<:MType}
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    node = getfield(agent, :node)
    model = getfield(agent, :model)
    list = Vector{GraphAgent{S, T}}()
    for i in 1:n
        for (key, val) in dc_agent
            if key != :_extras 
                dc[key] = deepcopy(val)
            end
        end
        dc[:_extras] = PropDict()
        dc[:_extras]._active = agent._extras._active # property of being alive or dead is same as of previous agent
        dc[:_extras]._new = true
        agnew = GraphAgent{S, T}(1, node, dc, model)
        push!(list, agnew)
    end
    return list
end


"""
$(TYPEDSIGNATURES)

Returns a list of n 2d agents all having same (other than _extras) properties as `agent`.  
"""
function create_similar(agent::GraphAgent{S, T}) where {S<:MType, T<:MType}
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    node = getfield(agent, :node)
    model = getfield(agent, :model)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = deepcopy(val)
        end
    end
    dc[:_extras] = PropDict()
    dc[:_extras]._active = agent._extras._active # property of being alive or dead is same as of previous agent
    dc[:_extras]._new = true
    agnew = GraphAgent{S, T}(1, node, dc, model)
    return agnew
end





