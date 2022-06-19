mutable struct AgentDict3DGrid{K, V} <: AbstractAgent3D{K, V}
    pos::Tuple{Int, Int, Int}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    AgentDict3DGrid() = new{Symbol, Any}((1,1,1), Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function AgentDict3DGrid(pos, d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()   
        new{Symbol, Any}(pos, d, data)
    end
end

Base.IteratorSize(::Type{AgentDict3DGrid{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{AgentDict3DGrid{T}}) where T = IteratorEltype(T)


function update_grid!(agent::AgentDict3DGrid, patches::Nothing, pos)
    return
end

function update_grid!(agent::AgentDict3DGrid, patches::Array{PropDataDict{Symbol, Any},3}, pos)
    x,y,z = pos
    x0,y0,z0 = agent.pos
    i = agent._extras._id
    size = patches[1,1,1]._extras._size
    periodic = patches[1,1,1]._extras._periodic

    if periodic
        deleteat!(patches[x0,y0,z0]._extras._agents, findfirst(m->m==i, patches[x0,y0,z0]._extras._agents))
        a, b, c = mod1(x,size[1]), mod1(y,size[2]), mod1(z,size[3])
        push!(patches[a,b,c]._extras._agents, i)
        setfield!(agent, :pos, (a,b,c))
    elseif (all(0 .< (x,y,z)) && all( (x,y,z) .<= size))
        deleteat!(patches[x0,y0,z0]._extras._agents, findfirst(m->m==i, patches[x0,y0,z0]._extras._agents))
        push!(patches[x,y,z]._extras._agents, i)
        setfield!(agent, :pos, (x,y,z))
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
function grid_3d_agent(;pos::Tuple{Int, Int, Int} =(1,1,1), kwargs...)
    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._grid = nothing
    dict_agent[:_extras]._active = true

    return AgentDict3DGrid(pos, dict_agent)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 2d agents with properties specified as keyword arguments.
"""
function grid_3d_agents(n::Int; pos::Tuple{Int, Int, Int} =(1,1,1), kwargs...)
list = Vector{AgentDict3DGrid{Symbol, Any}}()
for i in 1:n
    agent = grid_3d_agent(;pos=pos, kwargs...)
    push!(list, agent)
end
return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n 2d agents all having same properties as `agent`.  
"""
function create_similar(agent::AgentDict3DGrid, n::Int)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    pos = getfield(agent, :pos)
    agents = grid_3d_agents(n;pos=pos, dc...)
    return agents
end


"""
$(TYPEDSIGNATURES)
Returns an agent with same properties as given `agent`. 
"""
function create_similar(agent::AgentDict3DGrid)
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = val
        end
    end
    pos = getfield(agent, :pos)
    agent = grid_3d_agent(;pos=pos, dc...)
    return agent
end





