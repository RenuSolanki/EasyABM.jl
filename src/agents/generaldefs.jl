
struct StaticPropException <: Exception
    err::String
end

Base.showerror(io::IO, e::StaticPropException) = print(io, e.err)

#throw(StaticPropException("Can not modify static property!"))


abstract type AbstractPropDict{K, V} <: AbstractDict{K, V} end

unwrap(d::T) where {T<:AbstractPropDict} = getfield(d, :d)
unwrap_data(d::T) where {T<:AbstractPropDict} = getfield(d, :data)
Base.getindex(d::T, i) where {T<:AbstractPropDict}  = getindex(unwrap(d), i)
Base.get(d::T, i, default) where {T<:AbstractPropDict} = get(unwrap(d), i, default)
Base.iterate(iter::T) where {T<:AbstractPropDict} = iterate(unwrap(iter))
Base.iterate(iter::T, state) where {T<:AbstractPropDict} = iterate(unwrap(iter), state)
Base.getproperty(d::T, n) where {T<:AbstractPropDict} = getindex(d, n)  #get value with . notation
Base.getproperty(d::T, n::Symbol) where {T<:AbstractPropDict} = getindex(d, n)
Base.length(d::T) where {T<:AbstractPropDict} = length(unwrap(d))