abstract type MType end #mortality type
struct Static <: MType end
struct Mortal <: MType end


abstract type SType end #space type
struct Periodic <: SType end
struct NPeriodic <: SType end

abstract type GType end #graph type
struct DirG <: GType end
struct SimG <: GType end


abstract type AbstractSpaceModel{T<:MType, S<:Union{Int, Float64}, P<:SType} end
abstract type AbstractSpaceModel2D{T,S,P}<:AbstractSpaceModel{T,S,P} end
abstract type AbstractSpaceModel3D{T,S,P}<:AbstractSpaceModel{T,S,P} end
abstract type AbstractGraphModel{S<:MType, T<:MType, G<:GType} end
abstract type AbstractPropGraph{S<:MType, G<:GType} end

is_periodic(model::AbstractSpaceModel{T,S,Periodic}) where {T,S} = true 
is_periodic(model::AbstractSpaceModel{T,S,NPeriodic}) where {T,S} = false


