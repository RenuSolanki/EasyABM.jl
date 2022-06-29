mutable struct Agent2D{K, V, S<:Union{Int, AbstractFloat}, P<:SType} <: AbstractAgent2D{K, V, S, P}
    id::Int
    pos::Vect{2, <:S}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    last_grid_loc::Tuple{Int, Int}
    model::Union{AbstractSpaceModel2D{<:MType, S, P}, Nothing}

    Agent2D() = new{Symbol, Any, Int, Periodic}(1, Vect(1,1),
    Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), 
    Dict{Symbol, Any}(), (1,1), nothing)
    function Agent2D{P}(id::Int, pos::Vect{2, S}, d::Dict{Symbol, Any}, model) where {S<:Union{Int, AbstractFloat}, P<:SType}
        data = Dict{Symbol, Any}() 
        new{Symbol, Any, S, P}(id, pos, d, data, (1,1), model)
    end
    function Agent2D{P}(id::Int, pos::Vect{2, S}, d::Dict{Symbol, Any}, data::Dict{Symbol, Any},model) where {S<:Union{Int, AbstractFloat}, P<:SType}
        new{Symbol, Any, S, P}(id, pos, d, data, (1,1), model)
    end
end

Base.IteratorSize(::Type{Agent2D{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{Agent2D{T}}) where T = IteratorEltype(T)


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
    - `keeps_record_of` : list of properties that the agent records during time evolution. 
"""
function con_2d_agent(;pos::Vect{2, S}=Vect(1.0,1.0),#GeometryBasics.Vec{2, S} = GeometryBasics.Vec(1.0,1.0), #NTuple{2, S}=(1.0,1.0), 
    space_type::Type{P}=Periodic,
    kwargs...) where {P<:SType, S<:AbstractFloat}

    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._active = true
    dict_agent[:_extras]._new = true

    return Agent2D{P}(1, pos, dict_agent, nothing)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 2d agents with properties specified as keyword arguments.
"""
function con_2d_agents(n::Int; pos::Vect{2, S}=Vect(1.0,1.0), #GeometryBasics.Vec{2, S} = GeometryBasics.Vec(1.0,1.0), #, 
    space_type::Type{P} = Periodic, 
    kwargs...) where {S<:AbstractFloat, P<:SType}

    list = Vector{Agent2D{Symbol, Any, S, P}}()
    for i in 1:n
        agent = con_2d_agent(;pos=pos, space_type = P, kwargs...)
        push!(list, agent)
    end
    return list
end

"""
$(TYPEDSIGNATURES)

Returns a list of n 2d agents all having same properties as `agent`.  
"""
function create_similar(agent::Agent2D{Symbol, Any, S, P}, n::Int) where {S<:Union{Int, AbstractFloat},P<:SType}
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    pos = getfield(agent, :pos)
    model = getfield(agent, :model)
    list = Vector{Agent2D{Symbol, Any, S, P}}()
    for i in 1:n
        for (key, val) in dc_agent
            if key != :_extras 
                dc[key] = deepcopy(val)
            end
        end
        dc_agent[:_extras] = PropDict()
        dc_agent[:_extras]._active = true
        dc_agent[:_extras]._new = true
        agent = Agent2D{P}(1, pos, dc_agent, model)
        push!(list, agent)
    end
    return list
end


"""
$(TYPEDSIGNATURES)
Returns an agent with same properties as given `agent`. 
"""
function create_similar(agent::Agent2D{Symbol, Any, S, P}) where {S<:Union{Int, AbstractFloat}, P<:SType}
    dc = Dict{Symbol, Any}()
    dc_agent = unwrap(agent)
    pos = getfield(agent, :pos)
    model = getfield(agent, :model)
    for (key, val) in dc_agent
        if key != :_extras 
            dc[key] = deepcopy(val)
        end
    end
    dc_agent[:_extras] = PropDict()
    dc_agent[:_extras]._active = true
    dc_agent[:_extras]._new = true
    agent = Agent2D{P}(1, pos, dc_agent,model)
    return agent
end





