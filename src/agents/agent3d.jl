struct AgentDict3D{K, V} <: AbstractPropDict{K, V}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    AgentDict3D() = new{Symbol, Any}(Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function AgentDict3D(d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()

        if !haskey(d,:_extras)
            d[:_extras]=PropDict()
            d[:_extras]._active = true
        end

        for (key,value) in d
            if !(key == :_extras) && !(key == :keeps_record_of)
                data[key]=typeof(value)[]
            end
        end    
        new{Symbol, Any}(d, data)
    end
end

Base.IteratorSize(::Type{AgentDict3D{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{AgentDict3D{T}}) where T = IteratorEltype(T)


function update_grid!(agent::AgentDict3D, grid::Nothing)
    nothing
end
function update_grid!(agent::AgentDict3D, patches::Dict{Tuple{Int, Int, Int},Union{PropDataDict{Symbol, Any},Bool,Int}})
    i = agent._extras._id
    xdim = patches[(-1,0,0)]
    ydim = patches[(0,-1,0)]
    zdim = patches[(0,0,-1)]
    periodic = patches[(-1,-1,-1)]
    x,y,z = agent.pos
    last_grid_loc = agent._extras._last_grid_loc

    if agent._extras._last_grid_loc != Inf
        deleteat!(patches[last_grid_loc]._extras._agents, findfirst(m->m==i, patches[last_grid_loc]._extras._agents))
    end
    if periodic || (x>0)&&(x<=xdim)&&(y>0)&&(y<=ydim)&&(z>0)&&(z<=zdim)
        p2 = mod1(Int(ceil(x)), xdim)
        q2 = mod1(Int(ceil(y)), ydim)
        r2 = mod1(Int(ceil(z)), zdim)
        push!(patches[(p2,q2,r2)]._extras._agents, i)
        agent._extras._last_grid_loc = (p2, q2, r2)
    else
        agent._extras._last_grid_loc= Inf
    end
end


function Base.setproperty!(agent::AgentDict3D, key::Symbol, x)

    if key == :_extras
        throw(StaticPropException("Can not modify private property : $key"))
    end

    if !(agent._extras._active)
        return
    end
    
    dict = unwrap(agent)
    dict_data = unwrap_data(agent)

    if (key!=:pos)&&(key!=:vel)
        dict[key] = x
    elseif key ==:pos
        dict[:pos]=GeometryBasics.Vec(Float64(x[1]),x[2], x[3])
        update_grid!(agent, agent._extras._grid)
    elseif key ==:vel
        dict[:vel]= GeometryBasics.Vec( Float64(x[1]), x[2], x[3])
    end

    if !(key in keys(dict_data)) && !(key == :_extras) && !(key == :keeps_record_of)
        dict_data[key] = typeof(dict[key])[]
    end

end

function Base.show(io::IO, ::MIME"text/plain", a::AgentDict3D) # works with REPL
    println(io, "Agent3D:")
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::AgentDict3D) # works with print
    println(io, "Agent3D:")
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::Vector{AgentDict3D}) # works with REPL
    println(io, "Agent3D list with $(length(v)) agents.")
end

function Base.show(io::IO, v::Vector{AgentDict3D}) # works with print
    println(io, "Agent3D list with $(length(v)) agents.")
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
function create_3d_agent(;kwargs...)
    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._grid = nothing
    dict_agent[:_extras]._active = true

    for (key, x) in dict_agent
        if (key ==:pos)||(key ==:vel)
            dict_agent[key]=GeometryBasics.Vec(Float64(x[1]),x[2], x[3])
        end

    end

    return AgentDict3D(dict_agent)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 3d agents with properties specified as keyword arguments.
"""
function create_3d_agents(n::Int; kwargs...)
list = Vector{AgentDict3D}()
for i in 1:n
    agent = create_3d_agent(;kwargs...)
    push!(list, agent)
end
return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n 3d agents all having same properties as `agent`.  
"""
function create_3d_agents(n::Int, agent::AgentDict3D)
list = Vector{AgentDict3D}()
for i in 1:n
    agent_new = deepcopy(agent)
    push!(list, agent_new)
end
return list
end



