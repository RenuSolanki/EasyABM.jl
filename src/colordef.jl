
const _palpha = 0.1
const _aalpha = 0.9
const _colors = ["white","black","red","green","blue","yellow","grey","orange","purple"]
const _colors_dict = Dict("white"=>RGBA(1, 1, 1, 1), "black"=>RGBA(0, 0, 0, 1), "red"=>RGBA(1, 0, 0, 1), 
"green"=>RGBA(0, 1, 0, 1), "blue"=>RGBA(0, 0, 1, 1), "yellow"=>RGBA(1, 1, 0, 1), 
"grey"=>RGBA(0.5,  0.5,  0.5,  1), "orange"=>RGBA(1.0,  0.65, 0.0,  1), "purple"=>RGBA(0.93, 0.51, 0.93, 1))
const bounding_box_color = RGBA(0, 0, 1, _palpha)
const patchwhite  = RGBA(1, 1, 1, _palpha)
const patchblack  = RGBA(0, 0, 0, _palpha)
const patchred    = RGBA(1, 0, 0, _palpha)
const patchgreen  = RGBA(0, 1, 0, _palpha)
const patchblue   = RGBA(0, 0, 1, _palpha)
const patchyellow = RGBA(1, 1, 0, _palpha)
const patchgrey   = RGBA(0.5,  0.5,  0.5,  _palpha)
const patchorange = RGBA(1.0,  0.65, 0.0,  _palpha)
const patchpurple = RGBA(0.93, 0.51, 0.93, _palpha)

const agentwhite  = RGBA(1, 1, 1, _aalpha)
const agentblack  = RGBA(0, 0, 0, _aalpha)
const agentred    = RGBA(1, 0, 0, _aalpha)
const agentgreen  = RGBA(0, 1, 0, _aalpha)
const agentblue   = RGBA(0, 0, 1, _aalpha)
const agentyellow = RGBA(1, 1, 0, _aalpha)
const agentgrey   = RGBA(0.5,  0.5,  0.5,  _aalpha)
const agentorange = RGBA(1.0,  0.65, 0.0,  _aalpha)
const agentpurple = RGBA(0.93, 0.51, 0.93, _aalpha)

struct Col
    val::RGBA{FixedPointNumbers.N0f8}
    function Col(nm::String)
        val=RGBA(0,0,0,0)
        if nm in _colors
            val=_colors_dict[nm]
        end
        new(val)
    end
    function Col(r,g,b)
        new(RGBA(r,g,b,1))
    end
    function Col(r,g,b,a)
        new(RGBA(r,g,b,a))
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::Col) # works with REPL
    println(io, "Col($(v.val.r),$(v.val.g),$(v.val.b),$(v.val.alpha))")
end

function Base.show(io::IO, v::Col) # works with print
    println(io, "Col($(v.val.r),$(v.val.g),$(v.val.b),$(v.val.alpha))")
end

function Base.show(io::IO, ::MIME"text/plain", v::Vector{<:Col}) # works with REPL
    l = length(v)
    println(io, "vector containing $l colors:")
    println(io, "")
    for cl in v
        println(io, cl)
    end
end

function Base.show(io::IO, v::Vector{<:Col}) # works with print
    l=length(v)
    println(io, "vector containing $l colors:")
    println(io, "")
    for cl in v
        println(io, cl)
    end
end

Base.string(col::Col)=string((col.val.r,col.val.g,col.val.b,col.val.alpha))

macro cl_str(x)
    func = esc(:Col)
    val = esc(x)
    quote
        $func($val)
    end
end