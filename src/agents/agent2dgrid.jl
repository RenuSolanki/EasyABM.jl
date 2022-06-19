mutable struct AgentDict2DGrid{K, V} <: AbstractAgent2D{K, V}
    pos::Tuple{Int, Int}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    AgentDict2DGrid() = new{Symbol, Any}((1,1),Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function AgentDict2DGrid(pos, d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()   
        new{Symbol, Any}(pos, d, data)
    end
end

Base.IteratorSize(::Type{AgentDict2DGrid{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{AgentDict2DGrid{T}}) where T = IteratorEltype(T)


function update_grid!(agent::AgentDict2DGrid, patches::Nothing, pos)
    return
end
function update_grid!(agent::AgentDict2DGrid, patches::Matrix{PropDataDict{Symbol, Any}}, pos)
    x,y = pos
    x0,y0 = agent.pos
    i = agent._extras._id
    size = patches[1,1]._extras._size
    periodic = patches[1,1]._extras._periodic

    if periodic
        deleteat!(patches[x0,y0]._extras._agents, findfirst(m->m==i, patches[x0,y0]._extras._agents))
        a, b = mod1(x,size[1]), mod1(y,size[2])
        push!(patches[a,b]._extras._agents, i)
        setfield!(agent, :pos, (a,b))
    elseif (all(0 .< (x,y)) && all( (x,y) .<= size))
        deleteat!(patches[x0,y0]._extras._agents, findfirst(m->m==i, patches[x0,y0]._extras._agents))
        push!(patches[x,y]._extras._agents, i)
        setfield!(agent, :pos, (x,y))
    end
end



"""
$(TYPEDSIGNATURES)

Creates a single 2d agent with properties specified as keyword arguments. 
Following property names are reserved for some specific agent properties 
    - pos : position
    - vel : velocity
    - shape : shape of agent
    - color : color of agent
    - size : size of agent
    - orientation : orientation of agent
    - keeps_record_of : list of properties that the agent records during time evolution. 
"""
function grid_2d_agent(;pos::NTuple{2, Int}=(1,1), kwargs...)
    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._grid = nothing
    dict_agent[:_extras]._active = true

    return AgentDict2DGrid(pos, dict_agent)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 2d agents with properties specified as keyword arguments.
"""
function grid_2d_agents(n::Int; pos::NTuple{2, Int}=(1,1),  kwargs...)
list = Vector{AgentDict2DGrid{Symbol, Any}}()
for i in 1:n
    agent = grid_2d_agent(;pos=pos, kwargs...)
    push!(list, agent)
end
return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n 2d agents all having same properties as `agent`.  
"""
function create_similar(agent::AgentDict2DGrid, n::Int)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    pos = getfield(agent, :pos)
    agents = grid_2d_agents(n; pos = pos, dc...)
    return agents
end


"""
$(TYPEDSIGNATURES)
Returns an agent with same properties as given `agent`. 
"""
function create_similar(agent::AgentDict2DGrid)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    pos = getfield(agent, :pos)
    agent = grid_2d_agent(;pos=pos, dc...)
    return agent
end





