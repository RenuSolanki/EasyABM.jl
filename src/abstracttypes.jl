abstract type MType end #mortality type
struct StaticType <: MType end
struct MortalType <: MType end


abstract type SType end #space type
struct PeriodicType <: SType end
struct NPeriodicType <: SType end

abstract type GType end #graph type
struct DirGType <: GType end
struct SimGType <: GType end


const Static = StaticType()
const Mortal = MortalType()
const Periodic = PeriodicType()
const NPeriodic = NPeriodicType()
const DirG = DirGType()
const SimG = SimGType()



abstract type AbstractSpaceModel{T<:MType, S<:Union{Int, Float64}, P<:SType} end
abstract type AbstractSpaceModel2D{T,S,P}<:AbstractSpaceModel{T,S,P} end
abstract type AbstractSpaceModel3D{T,S,P}<:AbstractSpaceModel{T,S,P} end
abstract type AbstractGraphModel{S<:MType, T<:MType, G<:GType} end
abstract type AbstractPropGraph{S<:MType, G<:GType} end

is_periodic(model::AbstractSpaceModel{T,S,PeriodicType}) where {T,S} = true 
is_periodic(model::AbstractSpaceModel{T,S,NPeriodicType}) where {T,S} = false


