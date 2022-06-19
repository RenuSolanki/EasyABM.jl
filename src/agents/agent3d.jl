mutable struct AgentDict3D{K, V} <: AbstractAgent3D{K, V}
    pos::NTuple{3, <:AbstractFloat}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    AgentDict3D() = new{Symbol, Any}((1.0,1.0,1.0),Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function AgentDict3D(pos, d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()  
        new{Symbol, Any}(pos, d, data)
    end
end

Base.IteratorSize(::Type{AgentDict3D{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{AgentDict3D{T}}) where T = IteratorEltype(T)


function update_grid!(agent::AgentDict3D, patches::Nothing, pos)
    return
end
function update_grid!(agent::AgentDict3D, patches::Array{PropDataDict{Symbol, Any},3}, pos)
    x,y,z = pos
    i = agent._extras._id
    size = patches[1,1,1]._extras._size
    periodic = patches[1,1,1]._extras._periodic

    if periodic || (all(0 .< pos) && all( pos .<= size))
        last_grid_loc = agent._extras._last_grid_loc
        deleteat!(patches[last_grid_loc...]._extras._agents, findfirst(m->m==i, patches[last_grid_loc...]._extras._agents))
        a,b,c = mod1(x,size[1]), mod1(y,size[2]), mod1(z,size[3])
        setfield!(agent, :pos, (a,b,c))
        a,b,c= Int(ceil(a)), Int(ceil(b)), Int(ceil(c))
        push!(patches[a,b,c]._extras._agents, i)
        agent._extras._last_grid_loc = (a,b,c)
    end
end






"""
$(TYPEDSIGNATURES)

Creates a single 3d agent with properties specified as keyword arguments.
Following property names are reserved for some specific agent properties 
    - pos : position
    - vel : velocity
    - shape : shape of agent
    - color : color of agent
    - size : size of agent
    - orientation : orientation of agent
    - keeps_record_of : list of properties that the agent records during time evolution. 
"""
function con_3d_agent(;pos::NTuple{3, <:AbstractFloat}=(1.0,1.0,1.0), kwargs...)
    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._grid = nothing
    dict_agent[:_extras]._active = true

    return AgentDict3D(pos, dict_agent)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 3d agents with properties specified as keyword arguments.
"""
function con_3d_agents(n::Int; pos::NTuple{3, <:AbstractFloat}=(1.0,1.0,1.0), kwargs...)
list = Vector{AgentDict3D{Symbol, Any}}()
for i in 1:n
    agent = con_3d_agent(; pos = pos, kwargs...)
    push!(list, agent)
end
return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n 3d agents all having same properties as `agent`.  
"""
function create_similar(agent::AgentDict3D, n::Int)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    pos = getfield(agent, :pos)
    agents = con_3d_agents(n; pos = pos, dc...)
    return agents
end

"""
$(TYPEDSIGNATURES)
Returns an agent with same properties as given `agent`. 
"""
function create_similar(agent::AgentDict3D)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    pos = getfield(agent, :pos)
    agent = con_3d_agent(; pos = pos, dc...)
    return agent
end



