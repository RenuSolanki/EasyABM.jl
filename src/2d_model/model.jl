
struct GridModel2D{T} <:AbstractGridModel{T}
    size::NTuple{2, Int}
    patches::Dict{Tuple{Int, Int}, Union{PropDataDict{Symbol, Any},Bool,Int}}
    agents::Vector{AgentDict2D}
    max_id::Base.RefValue{Int64}
    periodic::Bool
    graphics::Bool
    parameters::PropDataDict{Symbol, Any}
    record::NamedTuple{(:aprops, :pprops, :mprops), Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}}
    tick::Base.RefValue{Int64}
    GridModel2D(args...; atype::Type{T}) where T<:MType = new{atype}(args...)
end

const GridModel2DFixAgNum = GridModel2D{StaticType}
const GridModel2DDynAgNum = GridModel2D{MortalType}
    

function Base.getproperty(d::T, n::Symbol) where {T<:GridModel2D}
    if n == :tick
       return getfield(d, :tick)[]
    else
       return getfield(d, n)
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::GridModel2D{T}) where T # works with REPL
    if T==MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM GridModel2D{$T}: $str.")
end

function Base.show(io::IO, v::GridModel2D{T}) where T # works with print
    if T==MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM GridModel2D{$T}: $str.")
end







