struct PropDataDict{K, V} <: AbstractPropDict{K, V}
    d::Dict{Symbol, Any}
    data::Dict{Symbol, Any}
    PropDataDict() = new{Symbol, Any}(Dict{Symbol, Any}(:_extras => PropDict(Dict{Symbol,Any}(:_active=>true))), Dict{Symbol, Any}())
    function PropDataDict(d::Dict{Symbol, Any})
        data = Dict{Symbol, Any}()
        
        if !haskey(d,:_extras)
            d[:_extras]=PropDict()
            d[:_extras]._active = true
        end
        new{Symbol, Any}(d, data)
    end
end

Base.IteratorSize(::Type{PropDataDict{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{PropDataDict{T}}) where T = IteratorEltype(T)

function Base.setproperty!(d::PropDataDict, key::Symbol, x)

    if !(d._extras._active)
        return
    end

    dict = unwrap(d)

    dict[key] = x
end

function Base.show(io::IO, ::MIME"text/plain", a::PropDataDict)# works with REPL
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, key, ": ", value)
        end
    end
end

function Base.show(io::IO, a::PropDataDict) # works with print
    for (key, value) in unwrap(a)
        if !(key == :_extras)
            println(io, key, ": ", value)
        end
    end
end