


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
    - `keeps_record_of` : list of properties that the agent records during time evolution. 
"""
function grid_3d_agent(;pos::Vect{3, Int} =Vect(1,1,1), #GeometryBasics.Vec{3, Int} = GeometryBasics.Vec(1,1,1),#Tuple{Int, Int, Int} =(1,1,1), 
    space_type::Type{P} = Periodic, kwargs...) where {P<:SType}
    dict_agent = Dict{Symbol, Any}(kwargs)

    if !haskey(dict_agent, :keeps_record_of)
        dict_agent[:keeps_record_of] = Symbol[]
    end
    
    dict_agent[:_extras] = PropDict()
    dict_agent[:_extras]._active = true
    dict_agent[:_extras]._new = true

    return Agent3D{P}(1, pos, dict_agent,nothing)
end

"""
$(TYPEDSIGNATURES)

Creates a list of n 2d agents with properties specified as keyword arguments.
"""
function grid_3d_agents(n::Int; pos::Vect{3, Int} =Vect(1,1,1), #GeometryBasics.Vec{3, Int} = GeometryBasics.Vec(1,1,1),#Tuple{Int, Int, Int} =(1,1,1), 
    space_type::Type{P} = Periodic, kwargs...) where {P<:SType}
    list = Vector{Agent3D{Symbol, Any, Int, P}}()
    for i in 1:n
        agent = grid_3d_agent(;pos=pos, space_type= P, kwargs...)
        push!(list, agent)
    end
    return list
end






