struct PropDict{K, V} <: AbstractPropDict{K, V}
    d::Dict{Symbol, Any}
    PropDict() = new{Symbol, Any}(Dict{Symbol, Any}())
    PropDict(d::Dict{Symbol, Any}) = new{Symbol, Any}(d)
end

Base.IteratorSize(::Type{PropDict{T}}) where T = IteratorSize(T)
Base.IteratorEltype(::Type{PropDict{T}}) where T = IteratorEltype(T)

function Base.setproperty!(d::PropDict, key::Symbol, x)
    dict = unwrap(d)
    dict[key] = x
end

function Base.show(io::IO, ::MIME"text/plain", a::PropDict)# works with REPL
    for (key, value) in unwrap(a)
        println(io, key, ": ", value)
    end
end

function Base.show(io::IO, a::PropDict) # works with print
    for (key, value) in unwrap(a)
        println(io, key, ": ", value)
    end
end