struct ContainerDataDict{K, V} <: AbstractPropDict{K, V}
    agents::Vector{Int}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    ContainerDataDict() = new{Symbol, Any}(Int[], Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function ContainerDataDict(d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()
        
        if !haskey(d,:_extras)
            d[:_extras]=PropDict()
            d[:_extras]._active = true
        end
        new{Symbol, Any}(Int[], d, data)
    end
end

Base.IteratorSize(::Type{ContainerDataDict{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{ContainerDataDict{T}}) where T = IteratorEltype(T)


function Base.getproperty(d::ContainerDataDict, n::Symbol)
    if n == :agents
        return getfield(d, n)
    else
        return getindex(d, n)
    end
end

function Base.setproperty!(d::ContainerDataDict, key::Symbol, x)

    if !(d._extras._active::Bool)
        return
    end

    dict = unwrap(d)

    dict[key] = x
end

function Base.show(io::IO, ::MIME"text/plain", a::ContainerDataDict)# works with REPL
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::ContainerDataDict) # works with print
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, key, ": ", value)
        end
    end
end