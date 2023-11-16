mutable struct Agent2D{S<:Union{Int, Float64}, P<:SType, T<:MType} <: AbstractAgent2D{Symbol, Any, S, P, T}
    id::Int
    pos::Vect{2, <:S}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    last_grid_loc::Tuple{Int, Int}
    model::Union{AbstractSpaceModel2D{T, S, P}, Nothing}

    Agent2D() = new{Int, PeriodicType, StaticType}(1, Vect(1,1),
    Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), 
    Dict{Symbol, Any}(), (1,1), nothing)
    function Agent2D{S, P, T}(id::Int, pos::Vect{2, S}, d::Dict{Symbol, Any}, model) where {S<:Union{Int, Float64}, P<:SType, T<:MType}
        data = Dict{Symbol, Any}() 
        new{S, P, T}(id, pos, d, data, (1,1), model)
    end
    function Agent2D{S, P, T}(id::Int, pos::Vect{2, S}, d::Dict{Symbol, Any}, data::Dict{Symbol, Any},model) where {S<:Union{Int, Float64}, P<:SType, T<:MType}
        new{S, P, T}(id, pos, d, data, (1,1), model)
    end
end

Base.IteratorSize(::Type{Agent2D{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{Agent2D{T}}) where T = IteratorEltype(T)


"""
$(TYPEDSIGNATURES)

Creates a single 2d agent with properties specified as keyword arguments. 
Following property names are reserved for some specific agent properties 
    - pos : position
    - shape : shape of agent
    - color : color of agent
    - size : size of agent
    - orientation : orientation of agent
    - `keeps_record_of` : Set of properties that the agent records during time evolution. 
"""
function con_2d_agent(;pos::Vect{2, S}=Vect(1.0,1.0),#GeometryBasics.Vec{2, S} = GeometryBasics.Vec(1.0,1.0), #NTuple{2, S}=(1.0,1.0), 
    space_type::P=Periodic, agent_type::T=Static, 
    kwargs...) where {P<:SType, S<:Float64, T<:MType}

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

    return Agent2D{S, P, T}(1, pos, dict_agent, nothing)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 2d agents with properties specified as keyword arguments.
"""
function con_2d_agents(n::Int; pos::Vect{2, S}=Vect(1.0,1.0), #GeometryBasics.Vec{2, S} = GeometryBasics.Vec(1.0,1.0), #, 
    space_type::P = Periodic, agent_type::T=Static, 
    kwargs...) where {S<:Float64, P<:SType, T<:MType}

    list = Vector{Agent2D{S, P, T}}()
    for i in 1:n
        agent = con_2d_agent(;pos=pos, space_type = space_type, agent_type= agent_type, kwargs...)
        push!(list, agent)
    end
    return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n 2d agents all having same (other than _extras) properties as `agent` if `agent` is alive.  
"""
function create_similar(agent::Agent2D{S, P, T}, n::Int) where {S<:Union{Int, Float64},P<:SType, T<:MType}
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    pos = getfield(agent, :pos)
    model = getfield(agent, :model)
    list = Vector{Agent2D{S, P, T}}()
    for i in 1:n
        for (key, val) in dc_agent
            if key != :_extras 
                dc[key] = deepcopy(val)
            end
        end
        dc[:_extras] = PropDict()
        dc[:_extras]._active = agent._extras._active # property of being alive or dead is same as of previous agent
        dc[:_extras]._new = true
        agnew = Agent2D{S, P, T}(1, pos, dc, model)
        push!(list, agnew)
    end
    return list
end


"""
$(TYPEDSIGNATURES)
Returns an agent with same (other than _extras) properties as given `agent`. 
"""
function create_similar(agent::Agent2D{S, P, T}) where {S<:Union{Int, Float64}, P<:SType, T<:MType}
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    pos = getfield(agent, :pos)
    model = getfield(agent, :model)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = deepcopy(val)
        end
    end
    dc[:_extras] = PropDict()
    dc[:_extras]._active = agent._extras._active # property of being alive or dead is same as of previous agent
    dc[:_extras]._new = true
    agnew= Agent2D{S, P, T}(1, pos, dc, model)
    return agnew
end





