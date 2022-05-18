
struct GraphModel{T,S} <: AbstractGraphModel{T,S}
    graph::Union{SimplePropGraph{T}, DirPropGraph{T}}
    agents::Vector{AgentDictGr}
    max_id::Base.RefValue{Int64}
    graphics::Bool
    parameters::PropDataDict{Symbol, Any}
    record::NamedTuple{(:aprops, :nprops, :eprops, :mprops), Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}}
    tick::Base.RefValue{Int64}
    GraphModel(args...; gtype::Type{T}, atype::Type{S}) where {T<:MType, S<:MType} = new{gtype, atype}(args...) 
end

const GraphModelFixAgNum = Union{GraphModel{ StaticType,  StaticType }, GraphModel{ MortalType, StaticType }}
const GraphModelDynAgNum = Union{GraphModel{ StaticType,  MortalType}, GraphModel{ MortalType, MortalType}}
const GraphModelFixGrTop = Union{GraphModel{ StaticType,  StaticType }, GraphModel{ StaticType,  MortalType}}
const GraphModelDynGrTop = Union{GraphModel{ MortalType, StaticType }, GraphModel{ MortalType, MortalType}}




function Base.getproperty(d::AbstractGraphModel, n::Symbol) 
    if n == :tick
       return getfield(d, :tick)[]
    else
       return getfield(d, n)
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::GraphModel{T, S}) where {T,S} # works with REPL
    if (T==MortalType)&&(S==MortalType)
        str = "In a {$T,$S} model graph topology can change and agents can take birth or die"
    end
    if (T==StaticType)&&(S==MortalType)
        str = "In a {$T,$S} model graph topology is fixed while agents can take birth or die"
    end
    if (T==StaticType)&&(S==StaticType)
        str = "In a {$T,$S} model both graph topology and agents number is fixed"
    end
    if (T==MortalType)&&(S==StaticType)
        str = "In a {$T,$S} model graph topology can change and agents number is fixed"
    end
    
    println(io, "SimpleABM GraphModel{$T,$S}: $str.")
end

function Base.show(io::IO, v::GraphModel{T,S}) where {T,S} # works with print
    if (T==MortalType)&&(S==MortalType)
        str = "In a {$T,$S} model graph topology can change and agents can take birth or die"
    end
    if (T==StaticType)&&(S==MortalType)
        str = "In a {$T,$S} model graph topology is fixed while agents can take birth or die"
    end
    if (T==StaticType)&&(S==StaticType)
        str = "In a {$T,$S} model both graph topology and agents number is fixed"
    end
    if (T==MortalType)&&(S==StaticType)
        str = "In a {$T,$S} model graph topology can change and agents number is fixed"
    end
    
    println(io, "SimpleABM GraphModel{$T,$S}: $str.")
end
