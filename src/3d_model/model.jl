
struct SpaceModel3D{T} <:AbstractSpaceModel{T}
    size::NTuple{3, Int}
    patches:: Array{PropDataDict{Symbol, Any},3}  
    agents::Union{Vector{AgentDict3D{Symbol, Any}}, Vector{AgentDict3DGrid{Symbol, Any}}}
    max_id::Base.RefValue{Int64}
    periodic::Bool
    graphics::Bool
    parameters::PropDataDict{Symbol, Any}
    record::NamedTuple{(:aprops, :pprops, :mprops), Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}}
    tick::Base.RefValue{Int64}
    SpaceModel3D(args...; atype::Type{T}) where T<:MType = new{atype}(args...)
end

    

function Base.getproperty(d::T, n::Symbol) where {T<:SpaceModel3D}
    if (n == :tick) || (n==:max_id)
       return getfield(d, n)[]
    else
       return getfield(d, n)
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::SpaceModel3D{T}) where T # works with REPL
    if T==MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM SpaceModel3D{$T}: $str.")
end

function Base.show(io::IO, v::SpaceModel3D{T}) where T # works with print
    if T==MortalType
        str = "In a $T model agents can take birth or die"
    else
        str = "In a $T model number of agents is fixed"
    end
    println(io, "EasyABM SpaceModel3D{$T}: $str.")
end







