
struct StaticPropException <: Exception
    err::String
end

Base.showerror(io::IO, e::StaticPropException) = print(io, e.err)

#throw(StaticPropException("Can not modify static property!"))


abstract type AbstractPropDict{K, V} <: AbstractDict{K, V} end
abstract type AbstractAgent2D{K, V} <: AbstractPropDict{K, V} end
abstract type AbstractAgent3D{K, V} <: AbstractPropDict{K, V} end

unwrap(d::T) where {T<:AbstractPropDict} = getfield(d, :d)
unwrap_data(d::T) where {T<:AbstractPropDict} = getfield(d, :data)
Base.getindex(d::T, i) where {T<:AbstractPropDict}  = getindex(unwrap(d), i)
Base.get(d::T, i, default) where {T<:AbstractPropDict} = get(unwrap(d), i, default)
Base.iterate(iter::T) where {T<:AbstractPropDict} = iterate(unwrap(iter))
Base.iterate(iter::T, state) where {T<:AbstractPropDict} = iterate(unwrap(iter), state)
Base.getproperty(d::T, n) where {T<:AbstractPropDict} = getindex(d, n)  #get value with . notation
Base.getproperty(d::T, n::Symbol) where {T<:AbstractPropDict} = getindex(d, n)
Base.length(d::T) where {T<:AbstractPropDict} = length(unwrap(d))

function Base.getproperty(d::Union{AbstractAgent2D, AbstractAgent3D}, n::Symbol)
    if n == :pos
        return getfield(d, :pos)
    else
        return getindex(d, n)
    end
end

function Base.setproperty!(agent::Union{AbstractAgent2D, AbstractAgent3D}, key::Symbol, x)

    if !(agent._extras._active)
        return
    end
    
    dict = unwrap(agent)

    if (key!=:pos)
        dict[key] = x
    else
        update_grid!(agent, agent._extras._grid, x)
    end
end

function Base.show(io::IO, ::MIME"text/plain", a::AbstractAgent2D) # works with REPL
    println(io, "Agent2D:")
    println(io," pos :", getfield(a, :pos))
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::AbstractAgent2D) # works with print
    println(io, "Agent2D:")
    println(io," pos :", getfield(a, :pos))
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::Vector{<:AbstractAgent2D}) # works with REPL
    println(io, "Agent2D list with $(length(v)) agents.")
end

function Base.show(io::IO, v::Vector{<:AbstractAgent2D}) # works with print
    println(io, "Agent2D list with $(length(v)) agents.")
end


function Base.show(io::IO, ::MIME"text/plain", a::AbstractAgent3D) # works with REPL
    println(io, "Agent3D:")
    println(io," pos :", getfield(a, :pos))
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::AbstractAgent3D) # works with print
    println(io, "Agent3D:")
    println(io," pos :", getfield(a, :pos))
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, "    ", key, ": ", value)
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::Vector{<:AbstractAgent3D}) # works with REPL
    println(io, "Agent3D list with $(length(v)) agents.")
end

function Base.show(io::IO, v::Vector{<:AbstractAgent3D}) # works with print
    println(io, "Agent3D list with $(length(v)) agents.")
end
