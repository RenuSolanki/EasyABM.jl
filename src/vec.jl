abstract type EasyVect{N, T} end

struct Vect{N, T<:Union{Int, Float64}} <: EasyVect{N, T}
    v::NTuple{N, T}
end

Base.iterate(iter::Vect{N, T}) where {N, T<:Union{Int, Float64}} = iterate(getfield(iter, :v))
Base.iterate(iter::Vect{N, T}, i::Int) where {N, T<:Union{Int, Float64}} = iterate(getfield(iter, :v), i)
Base.length(x::Vect{N}) where N = N
Base.eltype(x::Vect{N,T}) where{N,T} = T

Vect(x::Vararg{T, N}) where {T<:Union{Int, Float64}, N}=Vect(x)

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


Base.broadcasted(::typeof(*), x::Union{Int, Float64}, y::Vect{N}) where N = Vect(x .* y.v)
Base.broadcasted(::typeof(*), x::Vect{N}, y::Union{Int, Float64}) where N = Vect(x.v .* y)

Base.broadcasted(::typeof(/), x::Vect{N}, y::Union{Int, Float64}) where N = Vect(x.v ./ y)
Base.broadcasted(::typeof(<), x::Union{Int, Float64}, y::Vect{N}) where N = x .< y.v
Base.broadcasted(::typeof(<), x::Vect{N}, y::Union{Int, Float64}) where N = x.v .< y
Base.broadcasted(::typeof(>), x::Union{Int, Float64}, y::Vect{N}) where N = x .> y.v
Base.broadcasted(::typeof(>), x::Vect{N}, y::Union{Int, Float64}) where N = x.v .> y

Base.broadcasted(::typeof(<=), x::Union{Int, Float64}, y::Vect{N}) where N = x .<= y.v
Base.broadcasted(::typeof(<=), x::Vect{N}, y::Union{Int, Float64}) where N = x.v .<= y
Base.broadcasted(::typeof(>=), x::Union{Int, Float64}, y::Vect{N}) where N = x .>= y.v
Base.broadcasted(::typeof(>=), x::Vect{N}, y::Union{Int, Float64}) where N = x.v .>= y

Base.broadcasted(::typeof(==), x::Union{Int, Float64}, y::Vect{N}) where N = x .== y.v
Base.broadcasted(::typeof(==), x::Vect{N}, y::Union{Int, Float64}) where N = x.v .== y

Base.broadcasted(::typeof(<), x::Vect{N}, y::Vect{N}) where N = x.v .< y.v
Base.broadcasted(::typeof(>), x::Vect{N}, y::Vect{N}) where N = x.v .> y.v
Base.broadcasted(::typeof(<=), x::Vect{N}, y::Vect{N}) where N = x.v .<= y.v
Base.broadcasted(::typeof(>=), x::Vect{N}, y::Vect{N}) where N = x.v .>= y.v
Base.broadcasted(::typeof(==), x::Vect{N}, y::Vect{N}) where N = x.v .== y.v

Base.:+(x::Vect{N}, y::Vect{N}) where N = Vect(x.v .+ y.v)
Base.:-(x::Vect{N}, y::Vect{N}) where N = Vect(x.v .- y.v)
Base.:-(x::Vect{N}) where N = Vect(Tuple((-i for i in x)))
Base.:*(x::Union{Int, Float64}, y::Vect{N}) where N = Vect(x .* y.v)
Base.:*(x::Vect{N}, y::Union{Int, Float64}) where N = Vect(x.v .* y)
Base.:/(x::Vect{N}, y::Union{Int, Float64}) where N = Vect(x.v ./ y)

Base.isless(x::Vect{N}, y::Vect{N}) where N = isless(x.v, y.v)

zeros_as(v::Vect{N,T}) where {N, T} = Vect(Tuple((zero(T) for _ in v)))
zeros_as(v::NTuple{N,T}) where {N,T} = Tuple((zero(T) for _ in v))
