abstract type MType end
abstract type Static <: MType end
abstract type Mortal <: MType end


abstract type SType end
abstract type Periodic <: SType end
abstract type NPeriodic <: SType end

abstract type GType end
abstract type DirG <: GType end
abstract type SimG <: GType end


abstract type AbstractSpaceModel{T<:MType, S<:Union{Int, AbstractFloat}, P<:SType} end
abstract type AbstractSpaceModel2D{T,S,P}<:AbstractSpaceModel{T,S,P} end
abstract type AbstractSpaceModel3D{T,S,P}<:AbstractSpaceModel{T,S,P} end
abstract type AbstractGraphModel{S<:MType, T<:MType, G<:GType} end
abstract type AbstractPropGraph{S<:MType, G<:GType} end

is_periodic(model::AbstractSpaceModel{T,S,Periodic}) where {T,S} = true 
is_periodic(model::AbstractSpaceModel{T,S,NPeriodic}) where {T,S} = false


