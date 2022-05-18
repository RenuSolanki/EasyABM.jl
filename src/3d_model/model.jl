
struct GridModel3D{T} <:AbstractGridModel{T}
    size::NTuple{3, Int}
    patches::Dict{Tuple{Int, Int, Int}, Union{PropDataDict{Symbol, Any},Bool,Int}}
    agents::Vector{AgentDict3D}
    max_id::Base.RefValue{Int64}
    periodic::Bool
    graphics::Bool
    parameters::PropDataDict{Symbol, Any}
    record::NamedTuple{(:aprops, :pprops, :mprops), Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}}
    tick::Base.RefValue{Int64}
    GridModel3D(args...; atype::Type{T}) where T<:MType = new{atype}(args...)
end

const GridModel3DFixAgNum = GridModel3D{StaticType}
const GridModel3DDynAgNum = GridModel3D{MortalType}
    

function Base.getproperty(d::T, n::Symbol) where {T<:GridModel3D}
    if n == :tick
       return getfield(d, :tick)[]
    else
       return getfield(d, n)
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::GridModel3D{T}) where T # works with REPL
    if T==MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "SimpleABM GridModel3D{$T}: $str.")
end

function Base.show(io::IO, v::GridModel3D{T}) where T # works with print
    if T==MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "SimpleABM GridModel3D{$T}: $str.")
end







