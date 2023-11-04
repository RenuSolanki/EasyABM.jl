
struct SpaceModel2D{T, S<:Union{Int, Float64}, P<:SType} <:AbstractSpaceModel2D{T,S,P}
    size::NTuple{2, Int}
    patches:: Matrix{ContainerDataDict{Symbol, Any}}  
    patch_locs::Vector{Tuple{Int, Int}}
    agents::Vector{Agent2D{S, P, T}}
    agents_added::Vector{Agent2D{S, P, T}}
    agents_killed::Vector{Agent2D{S, P, T}}
    max_id::Base.RefValue{Int64}
    graphics::Bool
    properties::PropDataDict{Symbol, Any}
    record::NamedTuple{(:aprops, :pprops, :mprops), Tuple{Set{Symbol}, Set{Symbol}, Set{Symbol}}}
    tick::Base.RefValue{Int64}

    SpaceModel2D{S,P}() where {S,P} =  begin #needed for initially attaching with agents
        size = (1,1)
        patches = [ContainerDataDict(Dict{Symbol, Any}(:color => Col("white"))) for i in 1:1, j in 1:1]
        patch_locs = [(1,1)]
        agents = Vector{Agent2D{S, P, MortalType}}()
        agents_added =  Vector{Agent2D{S, P, MortalType}}()
        agents_killed = Vector{Agent2D{S, P, MortalType}}()
        max_id = Ref(1)
        graphics = true
        properties = PropDataDict()
        record = (aprops=Set{Symbol}([]), pprops=Set{Symbol}([]), mprops = Set{Symbol}([]))
        tick = Ref(1)
        new{MortalType,S,P}(size, patches, patch_locs, agents, agents_added, agents_killed, max_id, graphics, properties, record, tick) 
    end

    function SpaceModel2D{T, S, P}(size, patches, patch_locs, agents, max_id, graphics, properties, record, tick) where {T<:MType, S<:Float64, P<:SType} 
        properties._extras._offset = (0.0,0.0)
        agents_added = Vector{Agent2D{S, P, T}}()
        agents_killed = Vector{Agent2D{S, P, T}}()

        new{T, S, P}(size, patches, patch_locs, agents, agents_added, agents_killed, max_id, graphics, properties, record, tick)
    end
    function SpaceModel2D{T, S, P}(size, patches, patch_locs, agents, max_id, graphics, properties, record, tick) where {T<:MType, S<:Int, P<:SType} 
        properties._extras._offset = (-0.5,-0.5)
        agents_added = Vector{Agent2D{S, P, T}}()
        agents_killed = Vector{Agent2D{S, P, T}}()

        new{T, S, P}(size, patches, patch_locs, agents, agents_added, agents_killed, max_id, graphics, properties, record, tick)
    end
end


    

function Base.getproperty(d::T, n::Symbol) where {T<:SpaceModel2D}
    if (n == :tick) || (n==:max_id)
       return getfield(d, n)[]
    else
       return getfield(d, n)
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::SpaceModel2D{T, S, P}) where {T,S,P} # works with REPL
    if T<:MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM SpaceModel2D{$T, $S, $P}: $str.")
end

function Base.show(io::IO, v::SpaceModel2D{T, S,P}) where {T,S,P} # works with print
    if T<:MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM SpaceModel2D{$T, $S, $P}: $str.")
end

function Base.setproperty!(agent::Agent2D{S, P, MortalType}, key::Symbol, x) where {S<:Union{Int, Float64}, P<:SType}

    if !(agent._extras._active::Bool)
        return
    end
    
    dict = unwrap(agent)

    if (key!=:pos)
        dict[key] = x
    else
        update_grid!(agent, getfield(agent, :model)::SpaceModel2D{MortalType,S,P}, x)
    end
end

function Base.setproperty!(agent::Agent2D{S, P, StaticType}, key::Symbol, x) where {S<:Union{Int, Float64}, P<:SType}

    
    dict = unwrap(agent)

    if (key!=:pos)
        dict[key] = x
    else
        update_grid!(agent, getfield(agent, :model)::SpaceModel2D{StaticType,S,P}, x)
    end
end


function update_grid!(agent::Agent2D, model::Nothing, pos)
    return
end

function update_grid!(agent::Agent2D{S, P, T}, model::SpaceModel2D{T,S,P}, pos) where {T<:MType, S<:Float64, P<:PeriodicType}
    x,y = pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    last_grid_loc = getfield(agent,:last_grid_loc)
    deleteat!(patches[last_grid_loc...].agents::Vector{Int}, findfirst(m->m==i, patches[last_grid_loc...].agents::Vector{Int}))
    a, b = mod1(x,size[1]), mod1(y,size[2])
    setfield!(agent, :pos, Vect(a,b))
    a,b = Int(ceil(a)), Int(ceil(b))
    push!(patches[a,b].agents::Vector{Int}, i)
    setfield!(agent, :last_grid_loc, (a,b))
end

function update_grid!(agent::Agent2D{S, P, T}, model::SpaceModel2D{T,S,P}, pos) where {T<:MType, S<:Float64, P<:NPeriodicType}
    x,y = pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    if (all(0 .< pos) && all( pos .<= size))
        last_grid_loc = getfield(agent, :last_grid_loc)
        deleteat!(patches[last_grid_loc...].agents::Vector{Int}, findfirst(m->m==i, patches[last_grid_loc...].agents::Vector{Int}))
        setfield!(agent, :pos, pos)
        a,b = Int(ceil(x)), Int(ceil(y))
        push!(patches[a,b].agents::Vector{Int}, i)
        setfield!(agent, :last_grid_loc, (a,b))
    end
end


function update_grid!(agent::Agent2D{S, P, T},  model::SpaceModel2D{T,S,P}, pos) where {T<:MType, S<:Int, P<:PeriodicType}
    x,y = pos
    x0,y0 = agent.pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    deleteat!(patches[x0,y0].agents::Vector{Int}, findfirst(m->m==i, patches[x0,y0].agents::Vector{Int}))
    a, b = mod1(x,size[1]), mod1(y,size[2])
    push!(patches[a,b].agents::Vector{Int}, i)
    setfield!(agent, :pos, Vect(a,b))
    setfield!(agent, :last_grid_loc, (a,b))
end


function update_grid!(agent::Agent2D{S, P, T},  model::SpaceModel2D{T,S,P}, pos) where {T<:MType, S<:Int, P<:NPeriodicType}
    x,y = pos
    x0,y0 = agent.pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    if (all(0 .< pos) && all( pos .<= size))
        deleteat!(patches[x0,y0].agents::Vector{Int}, findfirst(m->m==i, patches[x0,y0].agents::Vector{Int}))
        push!(patches[x,y].agents::Vector{Int}, i)
        setfield!(agent, :pos, pos)
        setfield!(agent, :last_grid_loc, (x,y))
    end
end

