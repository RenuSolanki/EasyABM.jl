abstract type EasyVect{N, T} end

struct Vect{N, T<:Union{Int, AbstractFloat}} <: EasyVect{N, T}
    v::NTuple{N, T}
end

Base.iterate(iter::Vect{N, T}) where {N, T<:Union{Int, AbstractFloat}} = iterate(getfield(iter, :v))
Base.iterate(iter::Vect{N, T}, i::Int) where {N, T<:Union{Int, AbstractFloat}} = iterate(getfield(iter, :v), i)
Base.length(x::Vect{N}) where N = N
Base.eltype(x::Vect{N,T}) where{N,T} = T

Vect(x::Vararg{T, N}) where {T<:Union{Int, AbstractFloat}, N}=Vect(x)

function Base.show(io::IO, x::Vect)
    println(io, x.v)
end

Base.getindex(x::Vect{N}, i::Int) where N = x.v[i]

Base.broadcasted(::typeof(+), x::Vect{N}, y::Vect{N}) where N = Vect(x.v .+ y.v)
Base.broadcasted(::typeof(-), x::Vect{N}, y::Vect{N}) where N = Vect(x.v .- y.v)

Base.broadcasted(::typeof(+), x::Vect{N}, y::NTuple{N}) where N = Vect(x.v .+ y)
Base.broadcasted(::typeof(+), x::NTuple{N}, y::Vect{N}) where N = Vect(x .+ y.v)
Base.broadcasted(::typeof(-), x::Vect{N}, y::NTuple{N}) where N = Vect(x.v .- y)
Base.broadcasted(::typeof(-), x::NTuple{N}, y::Vect{N}) where N = Vect(x .- y.v)


Base.broadcasted(::typeof(*), x::Union{Int, AbstractFloat}, y::Vect{N}) where N = Vect(x .* y.v)
Base.broadcasted(::typeof(*), x::Vect{N}, y::Union{Int, AbstractFloat}) where N = Vect(x.v .* y)

Base.broadcasted(::typeof(/), x::Vect{N}, y::Union{Int, AbstractFloat}) where N = Vect(x.v ./ y)
Base.broadcasted(::typeof(<), x::Union{Int, AbstractFloat}, y::Vect{N}) where N = x .< y.v
Base.broadcasted(::typeof(<), x::Vect{N}, y::Union{Int, AbstractFloat}) where N = x.v .< y
Base.broadcasted(::typeof(>), x::Union{Int, AbstractFloat}, y::Vect{N}) where N = x .> y.v
Base.broadcasted(::typeof(>), x::Vect{N}, y::Union{Int, AbstractFloat}) where N = x.v .> y

Base.broadcasted(::typeof(<=), x::Union{Int, AbstractFloat}, y::Vect{N}) where N = x .<= y.v
Base.broadcasted(::typeof(<=), x::Vect{N}, y::Union{Int, AbstractFloat}) where N = x.v .<= y
Base.broadcasted(::typeof(>=), x::Union{Int, AbstractFloat}, y::Vect{N}) where N = x .>= y.v
Base.broadcasted(::typeof(>=), x::Vect{N}, y::Union{Int, AbstractFloat}) where N = x.v .>= y

Base.broadcasted(::typeof(==), x::Union{Int, AbstractFloat}, y::Vect{N}) where N = x .== y.v
Base.broadcasted(::typeof(==), x::Vect{N}, y::Union{Int, AbstractFloat}) where N = x.v .== y

Base.broadcasted(::typeof(<), x::Vect{N}, y::Vect{N}) where N = x.v .< y.v
Base.broadcasted(::typeof(>), x::Vect{N}, y::Vect{N}) where N = x.v .> y.v
Base.broadcasted(::typeof(<=), x::Vect{N}, y::Vect{N}) where N = x.v .<= y.v
Base.broadcasted(::typeof(>=), x::Vect{N}, y::Vect{N}) where N = x.v .>= y.v
Base.broadcasted(::typeof(==), x::Vect{N}, y::Vect{N}) where N = x.v .== y.v

Base.:+(x::Vect{N}, y::Vect{N}) where N = Vect(x.v .+ y.v)
Base.:-(x::Vect{N}, y::Vect{N}) where N = Vect(x.v .- y.v)
Base.:*(x::Union{Int, AbstractFloat}, y::Vect{N}) where N = Vect(x .* y.v)
Base.:*(x::Vect{N}, y::Union{Int, AbstractFloat}) where N = Vect(x.v .* y)
Base.:/(x::Vect{N}, y::Union{Int, AbstractFloat}) where N = Vect(x.v ./ y)

Base.isless(x::Vect{N}, y::Vect{N}) where N = isless(x.v, y.v)
