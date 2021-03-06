
struct SpaceModel2D{T, S<:Union{Int, AbstractFloat}, P<:SType} <:AbstractSpaceModel2D{T,S,P}
    size::NTuple{2, Int}
    patches:: Matrix{ContainerDataDict{Symbol, Any}}  
    agents::Vector{Agent2D{Symbol, Any, S, P}}
    agents_added::Vector{Agent2D{Symbol, Any, S, P}}
    agents_killed::Vector{Agent2D{Symbol, Any, S, P}}
    max_id::Base.RefValue{Int64}
    graphics::Bool
    parameters::PropDataDict{Symbol, Any}
    record::NamedTuple{(:aprops, :pprops, :mprops), Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}}
    tick::Base.RefValue{Int64}

    SpaceModel2D{S,P}() where {S,P} =  begin #needed for initially attaching with agents
        size = (1,1)
        agents = Vector{Agent2D{Symbol, Any, S, P}}()
        agents_added =  Vector{Agent2D{Symbol, Any, S, P}}()
        agents_killed = Vector{Agent2D{Symbol, Any, S, P}}()
        max_id = Ref(1)
        graphics = true
        parameters = PropDataDict()
        record = (aprops=Symbol[], pprops=Symbol[], mprops = Symbol[])
        tick = Ref(1)
        new{Mortal,S,P}(size, agents, agents_added, agents_killed, max_id, graphics, parameters, record, tick) 
    end

    function SpaceModel2D{T, S, P}(size, patches, agents, max_id, graphics, parameters, record, tick) where {T, S<:AbstractFloat, P} 
        parameters._extras._offset = (0.0,0.0)
        agents_added = Vector{Agent2D{Symbol, Any, S, P}}()
        agents_killed = Vector{Agent2D{Symbol, Any, S, P}}()

        new{T, S, P}(size, patches, agents, agents_added, agents_killed, max_id, graphics, parameters, record, tick)
    end
    function SpaceModel2D{T, S, P}(size, patches, agents, max_id, graphics, parameters, record, tick) where {T, S<:Int, P} 
        parameters._extras._offset = (-0.5,-0.5)
        agents_added = Vector{Agent2D{Symbol, Any, S, P}}()
        agents_killed = Vector{Agent2D{Symbol, Any, S, P}}()

        new{T, S, P}(size, patches, agents, agents_added, agents_killed, max_id, graphics, parameters, record, tick)
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
    if T==Mortal
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM SpaceModel2D{$T, $S,$P}: $str.")
end

function Base.show(io::IO, v::SpaceModel2D{T, S,P}) where {T,S,P} # works with print
    if T==Mortal
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM SpaceModel2D{$T, $S,$P}: $str.")
end

function Base.setproperty!(agent::Agent2D{Symbol, Any, S, P}, key::Symbol, x) where {S<:Union{Int, AbstractFloat}, P<:SType}

    if !(agent._extras._active::Bool)
        return
    end
    
    dict = unwrap(agent)

    if (key!=:pos)
        dict[key] = x
    else
        update_grid!(agent, getfield(agent, :model)::SpaceModel2D{<:MType,S,P}, x)
    end
end


function update_grid!(agent::Agent2D, model::Nothing, pos)
    return
end

function update_grid!(agent::Agent2D{Symbol, Any, <:AbstractFloat, P}, model::SpaceModel2D{T,S,P}, pos) where {T, S<:AbstractFloat, P<:Periodic}
    x,y = pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    last_grid_loc = getfield(agent,:last_grid_loc)
    deleteat!(patches[last_grid_loc...].agents, findfirst(m->m==i, patches[last_grid_loc...].agents))
    a, b = mod1(x,size[1]), mod1(y,size[2])
    setfield!(agent, :pos, Vect(a,b))
    a,b = Int(ceil(a)), Int(ceil(b))
    push!(patches[a,b].agents, i)
    setfield!(agent, :last_grid_loc, (a,b))
end

function update_grid!(agent::Agent2D{Symbol, Any, <:AbstractFloat, P}, model::SpaceModel2D{T,S,P}, pos) where {T, S<:AbstractFloat, P<:NPeriodic}
    x,y = pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    if (all(0 .< pos) && all( pos .<= size))
        last_grid_loc = getfield(agent, :last_grid_loc)
        deleteat!(patches[last_grid_loc...].agents, findfirst(m->m==i, patches[last_grid_loc...].agents))
        setfield!(agent, :pos, pos)
        a,b = Int(ceil(x)), Int(ceil(y))
        push!(patches[a,b].agents, i)
        setfield!(agent, :last_grid_loc, (a,b))
    end
end


function update_grid!(agent::Agent2D{Symbol, Any, Int, P},  model::SpaceModel2D{T,S,P}, pos) where {T, S<:Int, P<:Periodic}
    x,y = pos
    x0,y0 = agent.pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    deleteat!(patches[x0,y0].agents, findfirst(m->m==i, patches[x0,y0].agents))
    a, b = mod1(x,size[1]), mod1(y,size[2])
    push!(patches[a,b].agents, i)
    setfield!(agent, :pos, Vect(a,b))
end


function update_grid!(agent::Agent2D{Symbol, Any, Int, P},  model::SpaceModel2D{T,S,P}, pos) where {T, S<:Int, P<:NPeriodic}
    x,y = pos
    x0,y0 = agent.pos
    i = getfield(agent, :id)
    size = model.size
    patches = model.patches

    if (all(0 .< pos) && all( pos .<= size))
        deleteat!(patches[x0,y0].agents::Vector{Int}, findfirst(m->m==i, patches[x0,y0].agents::Vector{Int}))
        push!(patches[x,y].agents::Vector{Int}, i)
        setfield!(agent, :pos, pos)
    end
end

