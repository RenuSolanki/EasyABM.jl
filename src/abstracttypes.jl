abstract type MType end
abstract type StaticType <: MType end
abstract type MortalType <: MType end


abstract type AbstractSpaceModel{T<:MType} end
abstract type AbstractGraphModel{T<:MType, S<:MType} end
abstract type AbstractPropGraph{T<:MType} end

