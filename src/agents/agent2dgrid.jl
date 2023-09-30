



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
    - `keeps_record_of` : Set of properties that the agent records during time evolution. 
"""
function grid_2d_agent(;pos::Vect{2, Int}=Vect(1,1), #GeometryBasics.Vec{2, Int} = GeometryBasics.Vec(1,1), #NTuple{2, Int}=(1,1), 
    space_type::Type{P} = Periodic, kwargs...) where {P<:SType}

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

    return Agent2D{P}(1, pos, dict_agent, nothing)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 2d agents with properties specified as keyword arguments.
"""
function grid_2d_agents(n::Int; pos::Vect{2, Int}=Vect(1,1), #GeometryBasics.Vec{2, Int} = GeometryBasics.Vec(1,1),#NTuple{2, Int}=(1,1),  
 space_type::Type{P} = Periodic, kwargs...) where {P<:SType}
    list = Vector{Agent2D{Symbol, Any, Int, P}}()
    for i in 1:n
        agent = grid_2d_agent(;pos=pos, space_type = P, kwargs...)
        push!(list, agent)
    end
    return list
end






